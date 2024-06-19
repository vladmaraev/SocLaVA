import { setupButton } from "./parrot";

document.querySelector("#app")!.innerHTML = `
  <div>
    <div class="card">
      <button id="button" type="button">Warming up...</button>
    </div>
    <div class="card-img" id="img">
    </div>
  </div>
`;

setupButton(document.querySelector("#button")!);
