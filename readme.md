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

By default, the expected input filename to convert is `index.qmd` and the output format is `html`. If you want to change this, please use `INPUT_FILE` and `FORMAT` command line arguments like this: `make render INPUT_FILE="your_file.qmd" FORMAT="pdf"`, for example.

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

#### Additional parameters

##### Specifying the input and output folder

By default, these two folders are expected to be:

```text
/your_project
├── input
│   ├── ...
├── output
│   ├── ...
```

But you can override this. And you should do this when you're using the `{{< include ... >}}` Quarto directives. As soon as you're using relative paths in your documentation, you should precisely define the INPUT folder.

Let's say you've this situation:

```text
/your_project
├── input
    └── long_documentation
        ├── index.qmd
        └── sub
            ├── include-1.md
            └── sub
                └── include-2.md
```

in `./input/long_documentation/index.qmd` you'll use this directive: `{{< include sub/include-1.md >}}` so a relative path. In the `include-1.md` file, we also can use another include: `{{< include sub/include-2.md >}}`; still relative.

For this to work, you should use the `INPUT_FOLDER` argument and set to the root folder of your documentation so `make render INPUT_FOLDER="./input/long_documentation`. All relatives paths will then be calculated from there.

##### Logging

You can define the logging level by using the `LOG_LEVEL` command line argument. For instance: `make render LOG_LEVEL="debug"`. Don't specify a value for non logging.

##### Copying files or folders after rendering

Imagine this situation: you've a `.qmd` with links to static files like images or files (links to PDF or whatever).

Once the `.qmd` has been converted to an HTML file and place to the `output` folder, you still need to copy the static files from your `input` folder to the `output` one.

This is where the `FOLDERS_TO_COPY` CLI argument will be helpful. 

The following example will convert the `index.qmd` file to an HTML one will copy three folders too. 

```bash
make render INPUT_FILE="index.qmd" FOLDERS_TO_COPY="assets;images;publications"
```

Here is an illustration of the folder's structure you'll have after the rendering:

```text
/your_project
├── input
│   ├── assets
│   │   ├── ...
│   ├── images
│   │   ├── ...
│   ├── publications
│   │   ├── ...
│   ├── input.qmd
├── output
│   ├── assets
│   │   ├── ...
│   ├── images
│   │   ├── ...
│   ├── publications
│   │   ├── ...
│   ├── input.html
```

The `FILES_TO_COPY` argument deserves the same functionality when files are not stored in a sub-directory but in the same folder than the `.qmd` file.

#### Tips

* If you only have one `.qmd` file in your folder, you don't need to specify the name of the file. So, `make render INPUT_FILE="my_subfolder"` will process the `my_documentation.qmd` file is only that one is present (so will not force to name your file `index.qmd`).
* Use the `DEBUG=1` command line argument to enable debug output.
* Use the `SYNCHRO=1` command line argument to enable synchronization mode i.e. changes done in the Bash scripts (folder `.docker/scripts` and sub-folders) will be immediately synchronized with the Docker container.

### Starting an interactive shell in the Docker image

In case of needs, you can *jump* inside the Docker image by running the following command in the console:

```bash
make bash
```

This will create a new interactive shell in the Docker Quarto image.

### Remove the Docker image

If you think you'll no more use it, just run `make remove` to remove the Docker image and retrieve disk space.
