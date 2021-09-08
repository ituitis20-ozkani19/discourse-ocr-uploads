# frozen_string_literal: true

module Jobs
  class OcrUploadsTopic < ::Jobs::Base
    def log(str)
      if SiteSetting.discourse_ocr_uploads_verbose_logging
        Rails.logger.warn(str)
      end
    end

    def execute(args)
      topic = Topic.find(args[:topic_id])
      return unless topic

      log("OCR Plugin: [#{SecureRandom.base64[0,8]}] Processing topic ID #{topic.id}") 

      creds = {
        "type": "service_account",
        "private_key": SiteSetting.discourse_ocr_uploads_google_private_key.gsub("\\n", "\n"),
        "client_email": SiteSetting.discourse_ocr_uploads_google_client_email,
        "client_id": SiteSetting.discourse_ocr_uploads_google_client_id
      }
      annotator = Google::Cloud::Vision::V1::ImageAnnotator.new(credentials: creds)

      texts = []
      topic.posts.first.uploads.each do |upload|
        begin
          log("OCR Plugin: [#{SecureRandom.base64[0,8]}] Processing upload ID #{upload.id}") 

          image_url = upload.local? ? Discourse.store.path_for(upload) : upload.url
          image_url = "https:#{image_url}" if image_url && image_url =~ /^\/\// # prefix // with https://
          res = annotator.document_text_detection(image: image_url)

          txt = res.responses[0].full_text_annotation&.text
          if txt.nil? || txt.strip.empty?
            log("OCR Plugin: [#{SecureRandom.base64[0,8]}] Empty result for upload ID #{upload.id}")
          else
            texts.push(txt) 
            log("OCR Plugin: [#{SecureRandom.base64[0,8]}] Processed upload ID #{upload.id} - #{txt[0,20]}...") 
          end
        rescue => e
          Rails.logger.error("OCR Plugin: [#{SecureRandom.base64[0,8]}] Error calling Google Cloud API #{e.inspect}")
          next
        end
      end

      if texts.count > 0
        log("OCR Plugin: [#{SecureRandom.base64[0,8]}] Creating a post in topic #{topic.id}.")

        raw = texts.join("\n---\n")
        post = PostCreator.create(
          topic.user,
          skip_validations: true,
          topic_id: topic.id,
          raw: raw)
        unless post.nil?
          post.save(validate: false)
        end
      else
        log("OCR Plugin: [#{SecureRandom.base64[0,8]}] No text found so not creating a post in topic #{topic.id}.")
      end
    end
  end
end
