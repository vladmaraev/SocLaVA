import {
  assign,
  createActor,
  setup,
  AnyMachineSnapshot,
  fromPromise,
  fromCallback,
} from "xstate";
import { speechstate } from "speechstate";
// import { createBrowserInspector } from "@statelyai/inspect";
import { KEY } from "./azure";
import { SSE } from "sse";

interface Move {
  role: "assistant" | "user";
  content: string;
}

// const inspector = createBrowserInspector();

const azureCredentials = {
  endpoint:
    "https://swedencentral.api.cognitive.microsoft.com/sts/v1.0/issueToken",
  key: KEY,
};

const settings = {
  azureCredentials: azureCredentials,
  azureRegion: "swedencentral",
  asrDefaultCompleteTimeout: 0,
  asrDefaultNoInputTimeout: 10000,
  locale: "en-US",
  ttsDefaultVoice: "en-US-EchoMultilingualNeural",
};

const dmMachine = setup({
  actors: {
    setup_image: fromCallback(
      ({ sendBack, input }: { sendBack: any; input: string }) => {
        const element = document.querySelector("#img")!;
        element.innerHTML = `<canvas id="canvas" width="672" height="672"></canvas>`;
        const canvas = <HTMLCanvasElement>document.getElementById("canvas");
        const ctx = canvas.getContext("2d")!;
        const img = new Image();
        img.onload = () => {
          var hRatio = canvas.width / img.width;
          var vRatio = canvas.height / img.height;
          var ratio = Math.min(hRatio, vRatio);
          var centerShift_x = (canvas.width - img.width * ratio) / 2;
          var centerShift_y = (canvas.height - img.height * ratio) / 2;
          ctx.drawImage(
            img,
            0,
            0,
            img.width,
            img.height,
            centerShift_x,
            centerShift_y,
            img.width * ratio,
            img.height * ratio,
          );
          sendBack({ type: "IMAGE_LOADED" });
        };
        img.src = `img/${input}`;
      },
    ),
    getDescription: fromPromise<any, { model: string; image: string }>(
      async ({ input }) => {
        console.log(`Asking ${input.model}...`);
        const response = await fetch("http://localhost:10012/api/generate", {
          method: "POST",
          body: JSON.stringify({
            model: input.model,
            // keep_alive: 0,
            stream: false,
            prompt:
              "What's on this image? Please provide a description which would be suitable for a human to assess the artistic quality of the image. Be as precise and specific as possible.",
            images: [input.image],
          }),
        });
        return response.json();
      },
    ),

    fetchResponse: fromPromise<
      any,
      { model: string; moves: Move[]; lm: Move; imageDescription: string }
    >(async ({ input }) => {
      const body = {
        stream: true,
        model: input.model,
        messages: [
          {
            role: "system",
            content:
              "You will be chatting with the user using spoken language. Keep your response VERY brief. Please,answer with just one very short sentence!\n\n" +
              "Both you and the user are presented with an artwork and you need to express your opinion about it. In dialogue, you need to come to agreement about the artistic qualities of the work. You can 'see' the image through the vision module which tells you the following:\n\n " +
              input.imageDescription +
              "\n\nYou will be chatting with the user using spoken language. Keep your response VERY brief. Your response should always contain one very short sentence.",
            // images: [input.image],
          },
          ...[...input.moves],
        ],
      };
      console.log(`Asking ${input.model}...`, body);
      const response = await fetch(
        "http://localhost:10012/v1/chat/completions",
        {
          method: "POST",
          body: JSON.stringify(body),
        },
      );
      if (!response.body) return;
      const reader = response.body
        .pipeThrough(new TextDecoderStream())
        .getReader();
      let output = "";
      while (true) {
        let { value, done } = await reader.read();
        if (done) break;
        let dataDone = false;
        const arr = value!.split("\n");
        arr.forEach((data) => {
          if (data.length === 0) return; // ignore empty message
          if (data.startsWith(":")) return; // ignore sse comment message
          if (data === "data: [DONE]") {
            dataDone = true;
            return;
          }
          const json = JSON.parse(data.substring(6));
          output = `${output}${json.choices[0].delta.content}`;
          // console.debug("⌚", json.choices[0].delta.content);
        });
        if (dataDone) break;
      }
      console.log(output);
      return output;
    }),
  },
  actions: {
    random_image: assign(({ context }) => {
      console.log("choosing image...");
      const images = [
        "Mask.jpg",
        "Judith.jpg",
        "Misunderstood.jpg",
        // "Rodion.jpg",
      ];
      const random = Math.floor(Math.random() * images.length);
      const newIS = {
        ...context.is,
        image: images[random],
      };
      return { is: newIS };
    }),
    encode_image: assign(({}) => {
      console.log("base64 encoding image...");
      const canvas = <HTMLCanvasElement>document.getElementById("canvas");
      const image = canvas.toDataURL("image/jpeg").split(";base64,")[1];
      return { image64: image };
    }),

    /** speak and listen */
    speak_output_top: ({ context }) =>
      context.ssRef.send({
        type: "SPEAK",
        value: {
          utterance: context.is.output[0],
        },
      }),
    listen: ({ context }) =>
      context.ssRef.send({
        type: "LISTEN",
      }),

    /** update rules */
    enqueue_recognition_result: assign(({ context, event }) => {
      const utterance = event.value[0].utterance;
      const newIS = {
        ...context.is,
        lm: {
          role: "user",
          content: utterance,
        } as any,
        moves: [
          ...context.is.moves,
          {
            role: "user",
            content: utterance,
            // images: [context.image64],
          },
        ] as any,
        input: [utterance, ...context.is.input],
      };
      console.log("[IS enqueue_recognition_result]", newIS);
      return { is: newIS };
    }),
    enqueue_input_timeout: assign(({ context }) => {
      const utterance =
        "(the user is not saying anything or you can't hear them)";
      const newIS = {
        ...context.is,
        lm: {
          role: "user",
          content: utterance,
        } as any,
        moves: [
          ...context.is.moves,
          {
            role: "user",
            content: utterance,
          },
        ] as any, // FIXME
        input: ["(the user is not saying anything)", ...context.is.input],
      };
      console.log("[IS enqueue_input_timeout]", newIS);
      return { is: newIS };
    }),
    dequeue_input: assign(({ context }) => {
      const newIS = {
        ...context.is,
        input: context.is.input.slice(1),
      };
      console.log("[IS dequeue_input]", newIS);
      return { is: newIS };
    }),
    dequeue_output: assign(({ context }) => {
      const newIS = { ...context.is, output: context.is.output.slice(1) };
      console.log("[IS dequeue_output]", newIS);
      return { is: newIS };
    }),
    enqueue_output_from_input: assign(({ context }) => {
      const newIS = {
        ...context.is,
        output: [context.is.input[0], ...context.is.output],
      };
      console.log("[IS enqueue_output_from_input]", newIS);
      return { is: newIS };
    }),
    enqueue_output_from_llm: assign(({ context, event }) => {
      const move = {
        role: "assistant",
        content: event.output,
        image: [context.image64],
      };
      const newIS = {
        ...context.is,
        output: [event.output, ...context.is.output],
        lm: move,
        moves: [...context.is.moves, move],
      } as any; // FIXME
      console.log("[IS enqueue_output_from_llm]", newIS);
      return { is: newIS };
    }),
  },
  guards: {
    /** preconditions */
    lastInputIsTimeout: ({ context }) => context.is.input[0] === "timeout",
    inputIsNotEmpty: ({ context }) => !!context.is.input[0],
    outputIsNotEmpty: ({ context }) => !!context.is.output[0],
  },
  types: {} as {
    context: {
      ssRef?: any;
      is: {
        input: string[];
        output: string[];
        image: string;
        moves: Move[];
        lm: Move;
      };
      image64?: string;
      imageDescription?: string;
    };
  },
}).createMachine({
  context: {
    is: {
      input: [],
      output: ["Hi there! Let's start our discussion!"],
      moves: [
        {
          role: "assistant",
          content: "Hi there! Let's start our discussion!",
        },
      ],
      image: "",
      lm: {
        role: "assistant",
        content: "Hi there! Let's start our discussion!",
      },
    },
  },
  id: "DM",
  initial: "Prepare",
  states: {
    Prepare: {
      entry: [
        "random_image",
        // "setup_page",
        assign({
          ssRef: ({ spawn }) => spawn(speechstate, { input: settings }),
        }),
        ({ context }) => context.ssRef.send({ type: "PREPARE" }),
      ],
      on: { ASRTTS_READY: "SetupImage" },
    },
    SetupImage: {
      invoke: { src: "setup_image", input: ({ context }) => context.is.image },
      on: { IMAGE_LOADED: "GetDescription" },
    },
    GetDescription: {
      entry: "encode_image",
      invoke: {
        src: "getDescription",
        input: ({ context }) => ({
          model: "llava:34b-v1.6",
          image: context.image64!,
        }),
        onDone: {
          actions: [
            ({ event }) => console.log(event.output),
            assign({ imageDescription: ({ event }) => event.output.response }),
          ],
          target: "WarmUpChatLLM",
        },
      },
    },
    WarmUpChatLLM: {
      invoke: {
        src: "fetchResponse",
        input: ({ context }) => ({
          model: "mistral",
          moves: context.is.moves,
          lm: context.is.lm,
          imageDescription: context.imageDescription!,
        }),
        onDone: { target: "WaitToStart" },
      },
    },
    WaitToStart: {
      on: {
        CLICK: "Main",
      },
    },
    Main: {
      initial: "Process",
      states: {
        Process: {
          always: [
            {
              guard: "lastInputIsTimeout",
              actions: "dequeue_input",
            },
            {
              guard: "inputIsNotEmpty",
              actions: ["dequeue_input"],
            },
            {
              guard: "outputIsNotEmpty",
              actions: ["speak_output_top", "dequeue_output"],
            },
          ],
          on: { SPEAK_COMPLETE: "Ask" },
        },
        Ask: {
          entry: "listen",
          on: {
            RECOGNISED: {
              target: "GenerateOutput",
              actions: "enqueue_recognition_result",
            },
            ASR_NOINPUT: {
              target: "GenerateOutput",
              // actions: "enqueue_input_timeout",
            },
          },
        },
        GenerateOutput: {
          invoke: {
            src: "fetchResponse",
            input: ({ context }) => ({
              model: "mistral",
              moves: context.is.moves,
              lm: context.is.lm,
              imageDescription: context.imageDescription!,
            }),
            onDone: { actions: "enqueue_output_from_llm", target: "Process" },
          },
        },
      },
    },
  },
});

export const dmActor = createActor(dmMachine, {
  // inspect: inspector.inspect,
}).start();

let is = dmActor.getSnapshot().context.is;
console.log("[IS (initial)]", is);
dmActor.subscribe((snapshot: AnyMachineSnapshot) => {
  /* if you want to log some parts of the state */
  // is !== snapshot.context.is && console.log("[IS]", snapshot.context.is);
  is = snapshot.context.is;
});

export function setupButton(element: HTMLElement) {
  element.addEventListener("click", () => {
    dmActor.send({ type: "CLICK" });
  });
  dmActor.subscribe((snapshot: AnyMachineSnapshot) => {
    if (snapshot.value === "WaitToStart") {
      element.innerHTML = "Click to start!";
    } else if (["GetDescription", "WarmUpChatLLM"].includes(snapshot.value)) {
      element.innerHTML = "Warming up...";
    } else {
      let meta: { view?: string } = Object.values(
        snapshot.context.ssRef.getSnapshot().getMeta(),
      )[0] || { view: undefined };
      element.innerHTML = meta.view as string;
      if (meta.view === "speaking") {
        element.style.backgroundColor = "#eeff76";
      }
      if (meta.view === "recognising") {
        element.style.backgroundColor = "#ff7676";
      }
    }
  });
}
