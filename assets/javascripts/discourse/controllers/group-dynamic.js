import Controller from "@ember/controller";
import { bind } from "discourse-common/utils/decorators";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { tracked } from "@glimmer/tracking";
import { action } from '@ember/object';

export default class GroupDynamicController extends Controller {
  @tracked loading = false;
  @tracked deploying = false;
  @tracked results = this.model.results;
  @tracked message = '';
  @tracked messageType = '';
  @tracked dirty = false;

  constructor() {
    super(...arguments);
    this.observeDeploying();
  }
  @action
  updateValue(event) {
    this.model.dynamic_rule = event.target.value;
    this.dirty = true;
  }

  get spinning() {
    return this.loading || this.deploying;
  }

  get disabled() {
    if (this.model.dynamic_progress > 0) {
      this.deploying = true;
    }
    return this.loading || this.deploying || !this.dirty;
  }

  @bind
  async run() {
    this.loading = true;
    this.dirty = false;
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
        this.deploying = true;
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
        this.loading = false;
    }
  }

  observeDeploying() {
    this.addObserver('deploying', this, this.deployingChanged);
  }

  deployingChanged() {
    if (this.deploying) {
      this.startPolling();
    } else {
      this.stopPolling();
    }
  }

  startPolling() {
    this.stopPolling();
    this.intervalId = setInterval(() => {
      ajax(`/g/${this.model.name}.json`).then(response => {
        if ((response.group.dynamic_progress || 100) == 100) {
          this.model = response.group;
          this.set('deploying', false);
        }
      }).catch(popupAjaxError);
    }, 5000);
  }

  stopPolling() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }
}