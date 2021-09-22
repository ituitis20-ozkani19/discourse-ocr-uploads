# Discourse OCR Uploads

This plugin uses the Google Cloud Vision API to perform Optical Character Recognition (OCR) on the images in the first post of a topic. It will then create a second post containing the recognized text.

## Installation

To install the plugin see https://meta.discourse.org/t/install-a-plugin/19157

## Configuration

* Create a service account on Google Cloud Platform [Creating and managing service accounts | Cloud IAM Documentation ](https://cloud.google.com/iam/docs/creating-managing-service-accounts) and create a key. Google will trigger a download of a JSON file. Open this in any text editor.
* Copy the value of the `client_id` field into the `discourse ocr uploads google client id` setting.
* Copy the value of the `client_email` field into the `discourse ocr uploads google client email` setting.
* Copy the value of the `private_key` field into the `discourse ocr uploads google private key` setting. Make sure to remove the surrounding quotes but leave the `-----BEGIN PRIVATE KEY-----` in the beginning and the `-----END PRIVATE KEY-----\n` at the end.
* Enable the plugin

The plugin can be enabled on a per-category basis. Go to the category settings tab, look for the **OCR Uploads** heading and check **Perform OCR on the images in the first post of a topic**.

## Usage

In the eligible categories, any first post in a topic will be scanned for uploaded images. These will be processed by the Cloud Vision API and a second post will appear containing the recognized text.
