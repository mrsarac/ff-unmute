use fframes::{
    CombinedMediaProvider, EncoderOptions, MediaDirectory, MediaProvider, RenderOptions,
    StaticMediaProvider,
};
#[path = "../../tools/backend.rs"]
mod backend;
use flat::{FlatMedia, FlatVideo};
use std::process::ExitCode;

fn main() -> ExitCode {
    let fonts = FlatMedia::prepare().expect("media");
    // music.wav (from music/synth.py) feeds the spectrum panel.
    let dir = MediaDirectory::read_folder("out/pass").expect("out/pass: run music/synth.py first");
    let pass = dir.process_media_source().expect("out/pass media");
    let media = CombinedMediaProvider::from([&fonts as &dyn MediaProvider, &pass]);
    let video = FlatVideo::new();

    backend::run(
        &video,
        RenderOptions {
            media: Some(&media),
            default_font: "JetBrains Mono",
            // Near lossless: the lens pass films this file and magnifies it up to 3x.
            video_encoder_options: EncoderOptions {
                preferred_encoder: Some("libx264"),
                codec_params: Some(&[("crf", "8"), ("preset", "fast"), ("tune", "animation")]),
                ..Default::default()
            },
            ..Default::default()
        },
        "out/pass/flat.mp4",
        false,
    )
}
