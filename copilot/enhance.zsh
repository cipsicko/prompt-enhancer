# >>> Prompt Enhancer >>>
# Interactive prompt refiner for Copilot CLI.
# --effort low keeps the refiner step itself cheap (it's light work).
enhance() {
  copilot --effort low -i "$(cat ~/.config/prompt-enhancer/enhance.md)

The rough prompt to enhance:
$*"
}
# <<< Prompt Enhancer <<<
