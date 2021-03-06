import * as React from "react";
import { testGridInputs } from "./generate_grid_test";
import { GridInput, InputCell } from "../grid_input";
import { mount, shallow } from "enzyme";
import { GridInputProps, InputCellProps } from "../interfaces";

describe("<GridInput/>", () => {
  const fakeProps = (): GridInputProps => ({
    disabled: false,
    grid: testGridInputs(),
    xy_swap: true,
    onChange: jest.fn(() => jest.fn()),
    preview: jest.fn(),
    botPosition: { x: undefined, y: undefined, z: undefined },
    onUseCurrentPosition: jest.fn(),
  });

  it("renders", () => {
    const wrapper = mount(<GridInput {...fakeProps()} />);
    ["Starting X", "starting Y", "# of plants", "Spacing (MM)"]
      .map(string => expect(wrapper.text()).toContain(string));
  });

  it("uses current location", () => {
    const p = fakeProps();
    p.botPosition = { x: 1, y: 2, z: 3 };
    const wrapper = mount(<GridInput {...p} />);
    wrapper.find("button").first().simulate("click");
    expect(p.onUseCurrentPosition).toHaveBeenCalledWith({ x: 1, y: 2, z: 3 });
  });

  it("doesn't use current location", () => {
    const p = fakeProps();
    const wrapper = mount(<GridInput {...p} />);
    wrapper.find("button").first().simulate("click");
    expect(p.onChange).not.toHaveBeenCalled();
  });
});

describe("<InputCell/>", () => {
  const fakeProps = (): InputCellProps => ({
    gridKey: "numPlantsH",
    xy_swap: false,
    onChange: jest.fn(),
    preview: jest.fn(),
    grid: testGridInputs(),
  });

  it("calls onChange", () => {
    const p = fakeProps();
    const wrapper = shallow(<InputCell {...p} />);
    wrapper.find("input").first().simulate("change", {
      currentTarget: { value: "6" }
    });
    expect(p.onChange).toHaveBeenCalledWith(p.gridKey, 6);
  });
});
