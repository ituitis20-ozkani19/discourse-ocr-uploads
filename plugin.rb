# name: discourse-ocr-uploads
# about: Discourse OCR uploads plugin
# version: 1.0
# authors: michael@communiteq.com
# url: https://www.communiteq.com/

gem 'os', '1.1.1', require: true
gem_platform = OS.linux? ? 'x86_64-linux' : OS.mac? ? 'universal-darwin' : '' # only mac and linux will work
gem 'google-protobuf', '3.13.0', platform: gem_platform, require: false
gem 'googleapis-common-protos-types', '1.0.5', require: false
gem 'grpc', '1.31.1', platform: gem_platform, require: false
gem 'googleapis-common-protos', '1.3.10', require: false
gem 'signet', '0.14.0', require: false
gem 'memoist', '0.16.2', require: false
gem 'googleauth', '0.13.1', require: false
gem 'rly', '0.2.3', require: false
gem 'google-gax', '1.8.1', require: false
gem 'google-cloud-vision', '0.38.0', require: false

require 'google/cloud/vision/v1'

enabled_site_setting :discourse_ocr_uploads_enabled

PLUGIN_NAME ||= "discourse-ocr-uploads".freeze

after_initialize do
  DiscourseEvent.on(:topic_created) do |topic|
    return unless SiteSetting.discourse_ocr_uploads_enabled? && topic.category && topic.category.custom_fields['enable_ocr_uploads']&.downcase == 'true'

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
