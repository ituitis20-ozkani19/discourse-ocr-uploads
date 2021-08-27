export default {
  actions: {
    onChangeSetting(value) {
      this.set(
        "category.custom_fields.enable_ocr_uploads",
        value ? "true" : "false"
      );
    },
  },
};
