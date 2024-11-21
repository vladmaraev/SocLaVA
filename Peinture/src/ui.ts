import { setupButton } from "./parrot";
import { createClient } from "@supabase/supabase-js";
import { SUPABASE_KEY } from "./azure";

const supabaseUrl = "https://ttlfngopsrcdgjlvuitl.supabase.co";
const supabaseKey = SUPABASE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);

const form = <HTMLFormElement>document.querySelector("#questionnaire");

form.addEventListener(
  "submit",
  async (event) => {
    event.preventDefault();
    let formData = new FormData(form);
    const canvas = <HTMLCanvasElement>document.querySelector("#canvas")!;
    formData.append("image", canvas.ariaLabel as string);
    let obj: any = {};
    formData.forEach((value, key) => (obj[key] = value));
    console.log(obj);
    await supabase.from("questionnaire").insert(obj);
  },
  false,
);

setupButton(document.querySelector("#button")!);

// document.querySelector("#app")!.innerHTML = `
// `;
