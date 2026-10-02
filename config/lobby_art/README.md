# Lobby art

Place `.png` images in this directory to use them as the lobby background.
One image is picked at random every round; if the directory is empty, the
bundled `default.png` is used.

## Author attribution (optional)

Create an `authors.txt` file next to the images with one line per image:

```
my_art.png=Artist Name
another_art.png=Someone Else
```

The attribution is shown in the bottom right corner of the lobby.

## Where it comes from

This mirrors the CM13 (`cmss13`) `SSlobby_art` behavior: server operators
control the art through config files, no code changes required.
