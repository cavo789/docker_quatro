# Using Quatro in a Docker container

> [Video - How to run quarto documents in docker containers (pt. 1). Also: KaosMaps](https://youtu.be/PKSz_2BHPyg) / [Github repo](https://github.com/kaosmaps/quartainer/tree/main)
>
> [Quatro Docker examples](https://github.com/analythium/quarto-docker-examples)

## How to use

First, we will need to create our Docker image with an installation of Quatro. This can be achieved by running the following command: `make build`.

The `build` command will take time and will create a 1.5 GB huge image. We need to do this only once.

The second action to do, every time we will update our source document, is `make convert-html`.

That action will convert the `./input/index.qmd` file as an HTML document and create if needed all the necessary files (like images). The result of the `convert-html` action will be saved, by Quatro, in a `output` directory.

The last action will be `make start` to start the browser and show the converted file and, too, to copy the result in your, local, `output` folder.

So, in short, just run `clear && make build && make convert-html && make start` and you're sure everything is working. The `make build´ action is slow only during the first execution so it's not a problem to run it again and again.
