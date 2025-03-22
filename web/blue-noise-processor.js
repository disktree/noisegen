class BlueNoiseProcessor extends AudioWorkletProcessor {
  process(inputs, outputs, parameters) {
    const output = outputs[0];
    for (let channel = 0; channel < output.length; channel++) {
      let channelData = output[channel];
      for (let i = 0; i < channelData.length; i++) {
        let white = Math.random() * 2 - 1;
        let blue = (white - this.lastOut) * 0.95;
        this.lastOut = white;
        channelData[i] = blue;
      }
    }
    return true;
  }
}

registerProcessor("blue-noise-processor", BlueNoiseProcessor);
