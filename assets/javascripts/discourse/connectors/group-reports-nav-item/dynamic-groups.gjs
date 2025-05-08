import Component from "@glimmer/component";
import { inject as service } from "@ember/service"
import { LinkTo } from "@ember/routing";
import dIcon from "discourse-common/helpers/d-icon";
import i18n from "discourse-common/helpers/i18n";

export default class DynamicGroups extends Component {
  @service currentUser;

  get otherAutoGroup()
  {
    return this.args.outletArgs.group.automatic && !this.args.outletArgs.group.dynamic_rule;
  }

  get mustShow()
  {
    return this.currentUser?.admin;
  }

  <template>
    {{#if this.mustShow}}
      {{#unless this.otherAutoGroup}}
        <li>
          <LinkTo @route="group.dynamic">
            {{dIcon "wand-magic"}} {{i18n "dynamic_groups.button_title"}}
          </LinkTo>
        </li>
      {{/unless}}
    {{/if}}
  </template>
}