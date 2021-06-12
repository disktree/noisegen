
import js.html.audio.GainNode;
import js.Browser.document;
import js.Browser.window;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.audio.AnalyserNode;
import js.html.audio.AudioContext;
import js.lib.Promise;
import js.lib.Uint8Array;

var colorBg = "#000";
var colorFg = "#fff";

var audio : AudioContext;
var gain : GainNode;
var noise : String;
var analyser : AnalyserNode;
var noises : Map<String,Dynamic>;

var canvas : CanvasElement;
var ctx : CanvasRenderingContext2D;
var freqs : Uint8Array;
var times : Uint8Array;
var animationFrameId : Int;

function update( time : Float ) {

    animationFrameId = window.requestAnimationFrame( update );

    analyser.getByteFrequencyData( freqs );
    analyser.getByteTimeDomainData( times );

    var v : Float, x : Float, y : Float;
    var hw = canvas.width/2, hh = canvas.height/2;
    ctx.clearRect( 0, 0, canvas.width, canvas.height );
    ctx.strokeStyle = noise;
    ctx.beginPath();
    for( i in 0...analyser.fftSize ) {
        v = i * (Math.PI/2)/180;
        x = Math.cos(v) * ( 100+ times[i] );
        y = Math.sin(v) * ( 100+ times[i] );
        ctx.lineTo( hw + x, hh + y );
    }
    ctx.stroke(); 
}

function handleWindowResize(e) {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
}

function initAudio() : Promise<Map<String,Dynamic>> {

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
        return noises = [
            'white' => r[0],
            'pink' => r[1],
            'brown' => r[2]
        ];
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
        canvas.style.backgroundColor = '#000';
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;

        ctx = canvas.getContext2d();
        ctx.fillStyle = colorBg;
        ctx.strokeStyle = colorFg;

        var noiseTypes = ['white','brown','pink'];
        for( type in noiseTypes ) {
            var e = document.getElementById( type );
            e.style.textDecoration = 'line-through';
            e.onclick = _ -> {
                initAudio().then( _ -> {
                    if( animationFrameId == null ) {
                        animationFrameId = window.requestAnimationFrame( update );
                    }
                    if( e.style.textDecoration == 'none' ) {
                        e.style.textDecoration = 'line-through';
                        noises.get( type ).disconnect();
                    } else {
                        e.style.textDecoration = 'none';
                        noises.get( noise = type ).connect( analyser );
                    }
                });
            }
        }

        window.addEventListener( 'wheel', e -> {
            if( gain != null ) {
                if( e.deltaY < 0 ) {
                    gain.gain.value += 0.1;
                    gain.gain.value = Math.min( gain.gain.value, 1.0 );
                } else {
                    gain.gain.value -= 0.1;
                    gain.gain.value = Math.max( gain.gain.value, 0.0 );
                }
            }
        }, false );

        window.addEventListener( 'resize', handleWindowResize, false );
    }
}
