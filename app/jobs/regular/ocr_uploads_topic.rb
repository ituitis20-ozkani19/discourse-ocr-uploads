# frozen_string_literal: true

module Jobs
  class OcrUploadsTopic < ::Jobs::Base
    def execute(args)
      topic = Topic.find(args[:topic_id])
      return unless topic

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
          image_url = upload.local? ? Discourse.store.path_for(upload) : upload.url
          image_url = "https:#{image_url}" if image_url && image_url =~ /^\/\// # prefix // with https://
          res = annotator.document_text_detection(image: image_url)
          texts.push(res.responses[0].full_text_annotation&.text)
        rescue
          next
        end
      end

      if texts.count
        raw = texts.join("\n---\n")
        post = PostCreator.create(
          topic.user,
          skip_validations: true,
          topic_id: topic.id,
          raw: raw)
        unless post.nil?
          post.save(validate: false)
        end
      end
    end
  end
end
