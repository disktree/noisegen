class VelvetNoiseProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.density = 0.01; // Probability of an impulse occurring per sample
  }
  process(inputs, outputs, parameters) {
    const output = outputs[0];
    for (let channel = 0; channel < output.length; channel++) {
      let channelData = output[channel];
      for (let i = 0; i < channelData.length; i++) {
        if (Math.random() < this.density) {
          channelData[i] = Math.random() < 0.5 ? 1 : -1; // Randomly +1 or -1
        } else {
          channelData[i] = 0; // Silence
        }
      }
    }
    return true;
  }
}
registerProcessor("velvet-noise-processor", VelvetNoiseProcessor);
