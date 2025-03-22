class BrownNoiseProcessor extends AudioWorkletProcessor {
  process(inputs, outputs, parameters) {
    const output = outputs[0];
    let last = 0.0;
    output.forEach(channel => {
      for (let i = 0; i < channel.length; i++) {
        var white = Math.random() * 2 - 1;
        channel[i] = (last + (0.02 * white)) / 1.02;
        last = channel[i];
        channel[i] *= 3.5;
      }
    })
    return true;
  }
}
registerProcessor('brown-noise-processor', BrownNoiseProcessor);
