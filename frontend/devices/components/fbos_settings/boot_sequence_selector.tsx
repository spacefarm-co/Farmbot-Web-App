import * as React from "react";
import { connect } from "react-redux";
import { Everything } from "../../../interfaces";
import { getFbosConfig } from "../../../resources/getters";
import { FBSelect, DropDownItem, Row, Col } from "../../../ui";
import { edit, save } from "../../../api/crud";
import { TaggedFbosConfig, TaggedSequence } from "farmbot";
import { selectAllSequences, findSequenceById } from "../../../resources/selectors";
import { betterCompact } from "../../../util";
import { ColWidth } from "../farmbot_os_settings";
import { t } from "../../../i18next_wrapper";
import { Highlight } from "../maybe_highlight";
import { DeviceSetting } from "../../../constants";
import { DevSettings } from "../../../account/dev/dev_support";

interface Props {
  list: DropDownItem[];
  selectedItem: Readonly<DropDownItem> | undefined;
  config: TaggedFbosConfig;
  dispatch: Function;
}

export const sequence2ddi = (x: TaggedSequence): DropDownItem | undefined => {
  const { body } = x;
  const emptyScope = (body.args.locals.body || []).length == 0;
  if (emptyScope && body.id) {
    return { label: body.name, value: body.id };
  }

  return undefined;
};

export function mapStateToProps(p: Everything): Props {
  const { index } = p.resources;
  const fbosConfig = getFbosConfig(index);
  if (fbosConfig) {
    const list = betterCompact(selectAllSequences(index).map(sequence2ddi));
    const { boot_sequence_id } = fbosConfig.body;
    const bs = boot_sequence_id ?
      findSequenceById(index, boot_sequence_id) : undefined;
    return {
      list,
      selectedItem: bs ? sequence2ddi(bs) : undefined,
      config: fbosConfig,
      dispatch: p.dispatch
    };

  } else {
    throw new Error("No config found?");
  }
}

export class RawBootSequenceSelector extends React.Component<Props, {}> {
  onChange = (_selected: DropDownItem) => {
    const payload = { boot_sequence_id: _selected.value as number | undefined };
    this.props.dispatch(edit(this.props.config, payload));
    this.props.dispatch(save(this.props.config.uuid));
  }

  SelectionInput = () =>
    <FBSelect
      allowEmpty={true}
      list={this.props.list}
      selectedItem={this.props.selectedItem}
      onChange={this.onChange} />

  render() {
    const newFormat = DevSettings.futureFeature1Enabled();
    return <Highlight settingName={DeviceSetting.bootSequence}>
      <Row>
        <Col xs={newFormat ? 12 : ColWidth.label}>
          <label>
            {t("BOOT SEQUENCE")}
          </label>
        </Col>
        {!newFormat &&
          <Col xs={ColWidth.description}>
            <this.SelectionInput />
          </Col>}
      </Row>
      {newFormat &&
        <Row>
          <Col xs={12} className="no-pad">
            <this.SelectionInput />
          </Col>
        </Row>}
    </Highlight>;
  }
}

export const BootSequenceSelector =
  connect(mapStateToProps)(RawBootSequenceSelector);
