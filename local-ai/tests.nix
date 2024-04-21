{ self
, lib
, testers
, fetchzip
, fetchurl
, writers
, writeText
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
      # https://huggingface.co/lmstudio-community/Meta-Llama-3-8B-Instruct-GGUF
      # https://ai.meta.com/blog/meta-llama-3/
      model-gguf = fetchurl {
        url = "https://huggingface.co/lmstudio-community/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf";
        sha256 = "ab9e4eec7e80892fd78f74d9a15d0299f1e22121cea44efd68a7a02a3fe9a1da";
      };
      stopWord = "<|eot_id|>";
      # https://github.com/mudler/LocalAI/blob/master/embedded/models/llama3-instruct.yaml
      tmpl-chat-message = writeText "chat-message.tmpl" ''
        <|start_header_id|>{{if eq .RoleName "assistant"}}assistant{{else if eq .RoleName "system"}}system{{else if eq .RoleName "tool"}}tool{{else if eq .RoleName "user"}}user{{end}}<|end_header_id|>

        {{ if .Content -}}{{.Content -}}{{ end -}}${stopWord}'';
      tmpl-chat = writeText "chat.tmpl"
        "<|begin_of_text|>{{.Input }}<|start_header_id|>assistant<|end_header_id|>";
      # https://localai.io/advanced/#full-config-model-file-reference
      model-config = {
        name = "gpt-3.5-turbo";
        conext_size = 8192;
        parameters = {
          model = model-gguf.name;
          # defaults from:
          # https://deepinfra.com/meta-llama/Meta-Llama-3-8B-Instruct
          temperature = 0.7;
          top_p = 0.9;
          top_k = 0;
          max_tokens = 512;
          # following parameter leads to outputs like: !!!!!!!!!!!!!!!!!!!
          #repeat_penalty = 1;
          presence_penalty = 0;
          frequency_penalty = 0;
        };
        stopwords = [ stopWord ];
        # https://github.com/meta-llama/llama3/tree/main?tab=readme-ov-file#instruction-tuned-models
        template = {
          chat = lib.removeSuffix ".tmpl" tmpl-chat.name;
          chat_message = lib.removeSuffix ".tmpl" tmpl-chat-message.name;
        };
      };
      models = linkFarmFromDrvs "models" [
        model-gguf
        tmpl-chat
        tmpl-chat-message
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
