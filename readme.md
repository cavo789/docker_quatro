# Using Quarto in a Docker container

> [Video - How to run quarto documents in docker containers (pt. 1). Also: KaosMaps](https://youtu.be/PKSz_2BHPyg) / [Github repo](https://github.com/kaosmaps/quartainer/tree/main)
>
> [Quarto Docker examples](https://github.com/analythium/quarto-docker-examples)

## How to use

### Your first use, creating the Docker image

When you don't have it build the Docker image, you'll need to first run the next command on your computer:

```bash
make build
```

If you don't have `make` yet on your machine, you'll get an error message. Please install `make` by running the command below. When done, run `make build` once more (should works now).

```bash
sudo apt-get update && sudo apt-get -y install make
```

Running `make build` for the first time will create the image. This step can be very long (five minutes or more depending on your machine). When successfully done, you'll have a new Docker image, you can see it with:

```bash
docker image list | grep bosa/quarto
```

*The Docker image will be huge (2.5GB or more) due to the high number of installed dependencies.*

### Now use it and render your documentation

Now, every time you'll need to convert a documentation, just run `make render` on the console (to use default values).

By default, the expected input filename to convert is `index.qmd` and the output format is `html`. If you want to change this, please use `INPUT_FILE` and `OUTPUT_FORMAT` command line arguments like this: `make render INPUT_FILE="your_file.qmd" OUTPUT_FORMAT="pdf"`, for example.

To make things explicit, your directory structure will looks be something like below. By running `make render` in the `/your_project` folder, the script will search for the `input/input.qmd` in your directory structure and, if found, will render it and save the result to `output/input.html`.

```text
/your_project
├── input
│   ├── input.qmd
├── output
│   ├── input.html
```

> ℹ️ **TIP**
> If you're a developer and you wish to be able to update and synchronize bash scripts and run updated versions, you can run `make build && make render` after each changes (which is not the fastest way since you'll recreate the image every time) or, easier, share the scripts folder between your host and the Docker container like this: `docker run --rm -it -v ${PWD}/input:/project/input -v ${PWD}/output:/project/output -v ${PWD}/.docker/scripts:/project/scripts bosa/quarto`

### Starting an interactive shell in the Docker image

In case of needs, you can *jump* inside the Docker image by running the following command in the console:

```bash
make bash
```

This will create a new interactive shell in the Docker Quarto image.

### Remove the Docker image

If you think you'll no more use it, just run `make remove` to remove the Docker image and retrieve disk space.
