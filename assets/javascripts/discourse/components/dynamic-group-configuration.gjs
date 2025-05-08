import Component from "@glimmer/component";
import { inject as service } from "@ember/service"
import { action } from "@ember/object";
import { tracked } from '@glimmer/tracking';
import { htmlSafe } from "@ember/template";
import { on } from "@ember/modifier";
import { eq } from "truth-helpers";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";

import icon from "discourse-common/helpers/d-icon";
import DButton from "discourse/components/d-button";
import i18n from "discourse-common/helpers/i18n";
import I18n from "discourse-i18n";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class DynamicGroupConfiguration extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked loading = false;
  @tracked deploying = false;
  @tracked dirty = false;
  @tracked results = null;
  @tracked message = '';
  @tracked messageType = '';

  @tracked group;

  constructor() {
    super(...arguments);
    this.group = this.args.group;
    if (this.group.dynamic_progress > 0) {
      this.deploying = true;
      this.startPolling();
    }
  }

  get disabled() {
    return this.loading || this.deploying || !this.dirty;
  }

  get spinning() {
    return this.loading || this.deploying;
  }

  @action
  updateValue(event) {
    this.group.dynamic_rule = event.target.value;
    this.dirty = true;
  }

  @action
  async run() {
    this.loading = true;
    this.dirty = false;
    try {
      const response = await ajax(
        `/g/${this.group.name}/dynamic`,
        {
          type: "POST",
          data: {
            dynamic_rule: this.group.dynamic_rule,
          },
        }
      );

      this.results = response;

      if (response.success) {
        this.message = I18n.t('dynamic_groups.applying_changes');
        this.messageType = 'success';
        this.deploying = true;
        this.group.dynamic_progress = 1;
        this.startPolling();
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

  startPolling() {
    if (this.deploying) {
      this.message = I18n.t('dynamic_groups.applying_changes');
      this.messageType = 'success';
      this.intervalId = setInterval(() => {
        ajax(`/g/${this.group.name}.json`).then(response => {
          this.group = response.group;
          if (this.group.dynamic_progress <= 0) {
            this.message = I18n.t('dynamic_groups.applying_done');
            this.deploying = false;
            if (this.intervalId) {
              clearInterval(this.intervalId);
              this.intervalId = null;
            }
          }
        }).catch(popupAjaxError);
      }, 2000);
    }
  }

  <template>
    {{#unless this.group.automatic}}
      <section class="groups-dynamic-groups">
        <div class="explanation">{{htmlSafe (i18n "dynamic_groups.explanation")}}</div>
        <textarea
          disabled={{this.spinning}}
          id="ruleexpression"
          rows="5"
          cols="60"
          name="ruleexpression"
          {{on "input" this.updateValue}}>{{this.group.dynamic_rule}}</textarea>
        <div>
          <DButton
            @action={{this.run}}
            @label="dynamic_groups.apply_button"
            @class="btn-primary"
            @type="submit"
            @disabled={{this.disabled}}
            @isLoading={{this.spinning}}
          />
          {{#if this.message}}
            <span class="{{if (eq this.messageType 'success') 'success-bar' 'error-bar'}}">
              {{this.message}} {{#if this.deploying}}{{ this.group.dynamic_progress}}%{{/if}}
            </span>
          {{/if}}
        </div>
      </section>
    {{/unless}}
  </template>
}