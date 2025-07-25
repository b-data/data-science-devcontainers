
# Append the user's pixi bin dir to PATH
if [[ "$PATH" != *"$HOME/.pixi/bin"* ]] ; then
    PATH="$PATH:$HOME/.pixi/bin"
fi
