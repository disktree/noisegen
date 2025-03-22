class VioletNoiseProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.lastWhite = 0;
  }
  process(inputs, outputs, parameters) {
    const output = outputs[0];
    for (let channel = 0; channel < output.length; channel++) {
      let channelData = output[channel];
      for (let i = 0; i < channelData.length; i++) {
        let white = Math.random() * 2 - 1;
        let violet = white - this.lastWhite;
        this.lastWhite = white;
        channelData[i] = violet * 0.5;
      }
    }
    return true;
  }
}
registerProcessor("violet-noise-processor", VioletNoiseProcessor);
