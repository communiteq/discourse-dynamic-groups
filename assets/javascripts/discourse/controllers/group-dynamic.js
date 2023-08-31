import Controller from "@ember/controller";
import { bind } from "discourse-common/utils/decorators";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { tracked } from "@glimmer/tracking";
import { action } from '@ember/object';

export default class GroupDynamicController extends Controller {
    @tracked loading = false;
    @tracked results = this.model.results;

    @action
    updateValue(event) {
      this.model.dynamic_rule = event.target.value;
    }

    @bind
    async run() {
        this.loading = true;
    
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
          if (!response.success) {
            return;
          }
        } catch (error) {
          if (error.jqXHR?.status === 422 && error.jqXHR.responseJSON) {
            this.results = error.jqXHR.responseJSON;
          } else {
            popupAjaxError(error);
          }
        } finally {
          this.loading = false;
        }
      }
}