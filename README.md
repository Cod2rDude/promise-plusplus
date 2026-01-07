<h1 id="queues" align="center">promise-plusplus</h1>
<div align="center">
    <img src="https://img.shields.io/badge/version-0.0.1-orange" alt="Version">
    <br/>
    <a href="https://opensource.org/licenses/MIT">
        <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
    </a>
    <img src="https://img.shields.io/badge/Language-Luau-2C3E50?style=&logo=lua" alt="Luau">
    <img src="https://img.shields.io/badge/Maintained%3F-Sometimes-green.svg" alt="Luau">
    <img src="https://img.shields.io/badge/Open%20Source-%E2%9D%A4-brightgreen" alt="Luau">
</div>
<div align="center">
    A light-weight promise library
</div>

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Why does this even exist?](#why-does-this-even-exist)
    - [What is a promise?](#what-is-a-promise)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [API](#api)
- [Found a Bug?](#found-a-bug)
- [Contribution](#contribution)
  - [Contributing](#contributing)
  - [Guidelines](#guidelines)
- [LICENSE](#license)
- [References](#references)

## Why does this even exist?
I do not know but it's cool right? Im kidding here is why it really exists,

#### What is a promise?
Promise is an object that acts as a proxy for a result that is initially unknown, usually because the computation of its value is not yet complete. It allows you to associate handlers with an asynchronous action's eventual success value or failure reason.

More basically, instead of halting your main process (simply the script where you created the promise) waiting for return or failure of a function that takes time to process (eg: datastore or https request), it runs that function in background and handles failure or success results by itself thus never making your main process wait.

Promise-plusplus aims to be a lightweight and fast library while keeping Promise-A+ standard.

## Features

## Installation
To install this to your computer you have this options;

1. Clone this repository by running following command
    ```bash
    git clone https://github.com/Cod2rDude/promise-plusplus
    ```
2. Get the latest release of .rbxm file from [releases](../../releases)
3. Or add this as a submodule to your project
    ```bash
    git submodule add https://github.com/Cod2rDude/promise-plusplus [PATH]
    ```
Wally will be added in future.

## Usage

## API
Please check out source code for further info about api.

## Found a Bug?
If you encounter any issues or unexpected behavior, please let me know! Your feedback helps make this library more stable.

1. Check the [existing issues](../../issues) to see if it has already been reported.
2. If not, open a [new issue](../../issues/new) and describe the problem.
3. Provide a small code snippet to reproduce the bug if possible.

## Contribution
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

### Contributing
To maintain the stability of the library, **direct commits to the main branch are restricted.** Please follow the workflow below to suggest changes:

1.  **Fork the Project:** Create your own copy of this repository.
2.  **Create a Feature Branch:**
    ```bash
    git checkout -b feature/AmazingFeature
    ```
3.  **Commit your changes:**
    ```bash
    git commit -m 'Add some AmazingFeature'
    ```
4.  **Push to branch:**
    ```bash
    git push origin feature/AmazingFeature
    ```
5.  **Open a Pull Request:** Navigate to the original repository and click "New Pull Request". Describe your changes in detail so they can be reviewed.

Once your Pull Request is merged, GitHub will automatically list you in the official "Contributors" section of the repository. (i guess so)

After a successful merge, I will also manually add your name and contribution to the table below!

### Guidelines
We appreciate contributions you will make but we will also highly appreciate you to follow our guidelines while contributing.

1.  Of course make sure your code is efficient.
2.  No nsfw links, swearing or anything like those.
3.  Maybe follow the coding style we do.
4.  That's it!

<div id="contributors">
    <h2>Contributors</h2>
    <div align="center">
        <table width="75%">
            <thead>
                <tr>
                    <th align="left">Contributor</th>
                    <th align="left">Description</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td><b><a href="https://github.com/Cod2rDude">Cod2rDude</a></b></td>
                    <td>Creator</td>
                </tr>
                <tr>
                    <td><b><a href="https://github.com/scrpt2r">scrpt2r</a></b></td>
                    <td>Helped on __log__</td>
                </tr>
            </tbody>
        </table>
    </div>
</div>

## [LICENSE](./LICENSE)
This project is licensed under [The MIT License](https://opensource.org/license/mit)

## References

<div align="right">
    <a href="#queues">
        <img src="https://img.shields.io/badge/TOP-↑-blue?style=flat-square" alt="Back to Top">
    </a>
</div>