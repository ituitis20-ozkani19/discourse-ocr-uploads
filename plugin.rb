# name: discourse-ocr-uploads
# about: Discourse OCR uploads plugin
# version: 1.1
# authors: michael@communiteq.com
# url: https://www.communiteq.com/

gem 'os', '1.1.1', require: true
gem_platform = OS.linux? ? 'x86_64-linux' : OS.mac? ? 'universal-darwin' : '' # only mac and linux will work
gem 'google-protobuf', '3.4.0', platform: gem_platform, require: false
gem 'googleapis-common-protos-types', '1.3.1', require: false
gem 'grpc', '1.50.0', platform: gem_platform, require: false
gem 'googleapis-common-protos', '1.3.12', require: false
gem 'signet', '0.16.1', require: false
gem 'memoist', '0.16.2', require: false
gem 'googleauth', '1.2.0', require: false
gem 'rly', '0.2.3', require: false
gem 'gapic-common', '0.14.0', require: false
gem 'google-cloud-errors', '1.0.1', require: false
gem 'google-cloud-vision-v1', '0.9.0', require: false

require 'google/cloud/vision/v1'

enabled_site_setting :discourse_ocr_uploads_enabled

PLUGIN_NAME ||= "discourse-ocr-uploads".freeze

after_initialize do
  require_dependency File.expand_path('../app/jobs/regular/ocr_uploads_topic.rb', __FILE__)

  DiscourseEvent.on(:topic_created) do |topic|
    if SiteSetting.discourse_ocr_uploads_enabled? && topic.category && topic.category.custom_fields['enable_ocr_uploads']&.downcase == 'true'
      Jobs.enqueue_in(0, :ocr_uploads_topic, topic_id: topic.id)
    end
  end
end
