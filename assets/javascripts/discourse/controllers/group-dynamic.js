import Controller from "@ember/controller";
import { bind } from "discourse-common/utils/decorators";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { tracked } from "@glimmer/tracking";
import { action } from '@ember/object';

export default class GroupDynamicController extends Controller {
  @tracked loading = false;
  @tracked results = this.model.results;
  @tracked message = '';
  @tracked messageType = '';
  @tracked disabled = true;

  @action
  updateValue(event) {
    this.model.dynamic_rule = event.target.value;
    this.disabled = false;
  }

  @bind
  async run() {
    this.loading = true;
    this.disabled = true;
    try {
      const response = await ajax(
        `/g/${this.model.name}/dynamic`,
        {
          type: "POST",
          data: {
            dynamic_rule: this.model.dynamic_rule,
          },
        }
      );

      this.results = response;
      if (response.success) {
        this.message = "Operation successful!";
        this.messageType = 'success';
      } else {
        this.message = response.errors[0]; // Assuming errors is an array of messages
        this.messageType = 'error';
      }
    } catch (error) {
      if (error.jqXHR?.status === 422 && error.jqXHR.responseJSON) {
        this.message = error.jqXHR.responseJSON.errors[0];
        this.messageType = 'error';
      } else {
        popupAjaxError(error);
      }
    } finally {
     // this.loading = false;
    }
  }
}