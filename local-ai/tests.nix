{ self
, lib
, testers
, fetchzip
, fetchurl
, writers
, symlinkJoin
, linkFarmFromDrvs
, jq
}:
let
  common-config = { config, ... }: {
    imports = [ ./module.nix ];
    services.local-ai = {
      enable = true;
      package = self;
      threads = config.virtualisation.cores;
    };
  };
in
{
  version = testers.testVersion {
    package = self;
    version = "v" + self.version;
  };

  health = testers.runNixOSTest ({ config, ... }: {
    name = self.name + "-health";
    nodes.machine = common-config;
    testScript =
      let
        port = "8080";
      in
      ''
        machine.wait_for_open_port(${port})
        machine.succeed("curl -f http://localhost:${port}/readyz")
      '';
  });

  # https://localai.io/features/embeddings/#bert-embeddings
  bert =
    let
      # Note: q4_0 and q4_1 models can not be loaded
      model-ggml = fetchurl {
        url = "https://huggingface.co/skeskinen/ggml/resolve/main/all-MiniLM-L6-v2/ggml-model-f16.bin";
        sha256 = "9c195b2453a4fef60a4f6be3a88a39211366214df6498a4fe4885c9e22314f50";
      };
      model-config = {
        name = "embedding";
        parameters.model = model-ggml.name;
        backend = "bert-embeddings";
        embeddings = true;
      };
      models = linkFarmFromDrvs "models" [
        model-ggml
        (writers.writeYAML "namedontcare1.yaml" model-config)
      ];
      requests.request = {
        model = model-config.name;
        input = "Your text string goes here";
      };
    in
    testers.runNixOSTest {
      name = self.name + "-bert";
      nodes.machine = {
        imports = [ common-config ];
        virtualisation.cores = 2;
        virtualisation.memorySize = 2048;
        services.local-ai.models = models;
      };
      passthru = { inherit models requests; };
      testScript =
        let
          port = "8080";
        in
        ''
          machine.wait_for_open_port(${port})
          machine.succeed("curl -f http://localhost:${port}/readyz")
          machine.succeed("curl -f http://localhost:${port}/v1/models --output models.json")
          machine.succeed("${jq}/bin/jq --exit-status 'debug | .data[].id == \"${model-config.name}\"' models.json")
          machine.succeed("curl -f http://localhost:${port}/embeddings --json @${writers.writeJSON "request.json" requests.request} --output embeddings.json")
          machine.succeed("${jq}/bin/jq --exit-status 'debug | .model == \"embedding\"' embeddings.json")
        '';
    };

} // lib.optionalAttrs (!self.features.with_cublas && !self.features.with_clblas) {
  # https://localai.io/docs/getting-started/manual/
  llama =
    let
      model-gguf = fetchurl {
        url = "https://huggingface.co/TheBloke/Luna-AI-Llama2-Uncensored-GGUF/resolve/main/luna-ai-llama2-uncensored.Q4_K_M.gguf";
        sha256 = "6a9dc401c84f0d48996eaa405174999c3a33bf12c2bfd8ea4a1e98f376de1f15";
      };
      model-config = {
        name = "gpt-3.5-turbo";
        parameters = {
          model = model-gguf.name;
          temperature = 0.7;
        };
        backend = "llama";
      };
      models = linkFarmFromDrvs "models" [
        model-gguf
        (writers.writeYAML "namedontcare1.yaml" model-config)
      ];
      requests = {
        # https://localai.io/features/text-generation/#chat-completions
        chat-completions = {
          model = model-config.name;
          messages = [{ role = "user"; content = "Say this is a test!"; }];
        };
        # https://localai.io/features/text-generation/#edit-completions
        edit-completions = {
          model = model-config.name;
          instruction = "rephrase";
          input = "Black cat jumped out of the window";
        };
        # https://localai.io/features/text-generation/#completions
        completions = {
          model = model-config.name;
          prompt = "A long time ago in a galaxy far, far away";
        };
      };
    in
    testers.runNixOSTest {
      name = self.name + "-llama";
      nodes.machine = {
        imports = [ common-config ];
        virtualisation.cores = 4;
        virtualisation.memorySize = 8192;
        services.local-ai.models = models;
      };
      passthru = { inherit models requests; };
      testScript =
        let
          port = "8080";
        in
        ''
          machine.wait_for_open_port(${port})
          machine.succeed("curl -f http://localhost:${port}/readyz")
          machine.succeed("curl -f http://localhost:${port}/v1/models --output models.json")
          machine.succeed("${jq}/bin/jq --exit-status 'debug | .data[].id == \"${model-config.name}\"' models.json")
          machine.succeed("curl -f http://localhost:${port}/v1/chat/completions --json @${writers.writeJSON "request-chat-completions.json" requests.chat-completions} --output chat-completions.json")
          machine.succeed("${jq}/bin/jq --exit-status 'debug | .object == \"chat.completion\"' chat-completions.json")
          machine.succeed("curl -f http://localhost:${port}/v1/edits --json @${writers.writeJSON "request-edit-completions.json" requests.edit-completions} --output edit-completions.json")
          machine.succeed("${jq}/bin/jq --exit-status 'debug | .object == \"edit\"' edit-completions.json")
          machine.succeed("curl -f http://localhost:${port}/v1/completions --json @${writers.writeJSON "request-completions.json" requests.completions} --output completions.json")
          machine.succeed("${jq}/bin/jq --exit-status 'debug | .object ==\"text_completion\"' completions.json")
        '';
    };

} // lib.optionalAttrs (self.features.with_tts && !self.features.with_cublas && !self.features.with_clblas) {
  # https://localai.io/features/text-to-audio/#piper
  tts =
    let
      voice-en-us = fetchzip {
        name = "en-us-danny-low.onnx";
        url = "https://github.com/rhasspy/piper/releases/download/v0.0.2/voice-en-us-danny-low.tar.gz";
        hash = "sha256-5wf+6H5HeQY0qgdqnAG1vSqtjIFM9lXH53OgouuPm0M=";
        stripRoot = false;
      };
      ggml-tiny-en = fetchurl {
        url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en-q5_1.bin";
        hash = "sha256-x3xXZvHO8JtrfUfyG1Rsvd1BV4hrO11tT3CekeZsfCs=";
      };
      whisper-en = {
        name = "whisper-en";
        backend = "whisper";
        parameters.model = ggml-tiny-en.name;
      };
      piper-en = {
        name = "piper-en";
        backend = "piper";
        parameters.model = voice-en-us.name;
      };
      models = symlinkJoin {
        name = "models";
        paths = [
          voice-en-us
          (linkFarmFromDrvs "models" [
            (writers.writeYAML "namedontcare1.yaml" whisper-en)
            ggml-tiny-en
            (writers.writeYAML "namedontcare2.yaml" piper-en)
          ])
        ];
      };
      requests.request = {
        model = piper-en.name;
        backend = "piper";
        input = "Hello, how are you?";
      };
    in
    testers.runNixOSTest {
      name = self.name + "-tts";
      nodes.machine = {
        imports = [ common-config ];
        virtualisation.cores = 2;
        services.local-ai.models = models;
      };
      passthru = { inherit models requests; };
      testScript =
        let
          port = "8080";
        in
        ''
          machine.wait_for_open_port(${port})
          machine.succeed("curl -f http://localhost:${port}/readyz")
          machine.succeed("curl -f http://localhost:${port}/v1/models --output models.json")
          machine.succeed("${jq}/bin/jq --exit-status 'debug' models.json")
          machine.succeed("curl -f http://localhost:${port}/tts --json @${writers.writeJSON "request.json" requests.request} --output out.wav")
          machine.succeed("curl -f http://localhost:${port}/v1/audio/transcriptions --header 'Content-Type: multipart/form-data' --form file=@out.wav --form model=${whisper-en.name} --output transcription.json")
          machine.succeed("${jq}/bin/jq --exit-status 'debug | .segments | first.text == \"${requests.request.input}\"' transcription.json")
        '';
    };
}
