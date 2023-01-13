
import js.Browser.document;
import js.Browser.window;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.audio.AnalyserNode;
import js.html.audio.AudioContext;
import js.html.audio.GainNode;
import js.lib.Promise;
import js.lib.Uint8Array;

enum abstract NoiseType(String) from String to String {
    var white;
    var pink;
    var brown;
}

var color = { bg: "#000", fg: "#fff" };

var audio : AudioContext;
var gain : GainNode;
var noise : NoiseType;
var analyser : AnalyserNode;
var noises : Map<NoiseType,Dynamic>;
var activeNoises : Array<NoiseType> = [];

var canvas : CanvasElement;
var ctx : CanvasRenderingContext2D;
var freqs : Uint8Array;
var times : Uint8Array;
var animationFrameId : Int;

function update( time : Float ) {

    animationFrameId = window.requestAnimationFrame( update );

    analyser.getByteFrequencyData( freqs );
    analyser.getByteTimeDomainData( times );

    var v : Float;
    var hw = canvas.width/2, hh = canvas.height/2;
    ctx.clearRect( 0, 0, canvas.width, canvas.height );
    ctx.strokeStyle = noise;
    ctx.beginPath();
    for( i in 0...analyser.fftSize ) {
        v = i * (Math.PI/2)/180;
        ctx.lineTo(hw + Math.cos(v) * ( 100 + times[i] ), hh + Math.sin(v) * ( 100 + times[i]) );
    }
    ctx.stroke(); 
}

function handleWindowResize(e) {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
}

function initAudio() : Promise<Map<NoiseType,Dynamic>> {

    if( noises != null )
        return Promise.resolve( noises ); 

    audio = new AudioContext();

    gain = audio.createGain();
    gain.gain.value = 1.0;
    gain.connect( audio.destination );

    analyser = audio.createAnalyser();
    //analyser.smoothingTimeConstant = SMOOTHING;
    //analyser.fftSize = 1024;
    //analyser.minDecibels = -140;
    //analyser.maxDecibels = 0;
    analyser.connect( gain );

    freqs = new Uint8Array( analyser.frequencyBinCount );
    times = new Uint8Array( analyser.frequencyBinCount );

    function addWorklet( name : String ) {
        return untyped audio.audioWorklet.addModule('$name.js').then( r -> {
            return js.Syntax.code("new AudioWorkletNode({0},{1})", audio, name );
        }); 
    }

    return Promise.all([
        addWorklet('white-noise-processor'),
        addWorklet('pink-noise-processor'),
        addWorklet('brown-noise-processor'),
    ]).then( r -> {
        return noises = [white => r[0], pink => r[1], brown => r[2]];
    });

    /*
    var noiseBufferSize = 4096;

    var whiteNoise = audio.createScriptProcessor( noiseBufferSize, 1, 1 );
    whiteNoise.onaudioprocess = e -> {
        Noise.generateWhiteNoise( e.outputBuffer.getChannelData(0), noiseBufferSize );
    };

    var brownNoise = audio.createScriptProcessor( noiseBufferSize, 1, 1 );
    brownNoise.onaudioprocess = e -> {
        Noise.generateBrownNoise( e.outputBuffer.getChannelData(0), noiseBufferSize );
    };

    var pinkNoise = audio.createScriptProcessor( noiseBufferSize, 1, 1 );
    pinkNoise.onaudioprocess = e -> {
        Noise.generatePinkNoise( e.outputBuffer.getChannelData(0), noiseBufferSize );
    };
    */
}

function main() {

    window.onload = () -> {

        canvas = cast document.getElementById( 'spectrum' );
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        ctx = canvas.getContext2d();
        ctx.fillStyle = color.bg;
        ctx.strokeStyle = color.fg;

        var noiseTypes = [white, brown, pink];
        for( type in noiseTypes ) {
            var e = document.getElementById( type );
            e.onclick = _ -> {
                initAudio().then( (noises:Map<NoiseType,Dynamic>) -> {
                    if( animationFrameId == null ) {
                        animationFrameId = window.requestAnimationFrame( update );
                    }
                    var n = noises.get( noise = type );
                    if( e.classList.contains('active') ) {
                        e.classList.remove( 'active' );
                        n.disconnect();
                    } else {
                        e.classList.add( 'active' );
                        n.connect( analyser );
                    }
                });
            }
        }

        var volumeElement = document.getElementById("volume");
        var timer = new haxe.Timer( 2000 );
        window.addEventListener( 'wheel', e -> {
            if( gain != null ) {
                if( e.deltaY < 0 ) {
                    gain.gain.value += 0.1;
                    gain.gain.value = Math.min( gain.gain.value, 1.0 );
                } else {
                    gain.gain.value -= 0.1;
                    gain.gain.value = Math.max( gain.gain.value, 0.0 );
                }
                volumeElement.textContent = 'VOL:'+Std.int(gain.gain.value * 100);
                timer.run = () -> {
                    volumeElement.textContent = 'Noise';
                    timer.stop();
                    timer = new haxe.Timer( 2000 );
                }
            }
        }, false );

        window.addEventListener( 'resize', handleWindowResize, false );
    }
}
