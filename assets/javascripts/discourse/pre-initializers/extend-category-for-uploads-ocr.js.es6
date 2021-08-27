import Category from "discourse/models/category";

export default {
  name: "extend-category-for-uploads-ocr",

  before: "inject-discourse-objects",

  initialize() {
    Category.reopen({
      enable_ocr_uploads: Ember.computed(
        "custom_fields.enable_ocr_uploads",
        {
          get(fieldName) {
            return Ember.get(this.custom_fields, fieldName) === "true";
          },
        }
      ),
    });
  },
};
