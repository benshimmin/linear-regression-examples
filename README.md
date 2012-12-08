# linear-regression-examples

Examples of rendering lines of best fit with linear regression in CoffeeScript
using Raphaël and HTML5 Canvas.

[See a live demonstration.][demo]

[demo]: http://bas.cornucopic.com/linear-regression-examples/

## Documentation

The [CoffeeScript source][cs-src] provides thorough documentation on how this
project works.

[cs-src]: https://github.com/benshimmin/linear-regression-examples/blob/master/src/coffee/renderer.coffee

## Build

This project is built with CoffeeScript, HAML, and Sass. Compilation is
quite straightforward in each case.

### CoffeeScript

(Create a `js/` directory into which the CoffeeScript files will be compiled.)

    $ coffee -o js -c src/coffee/

### HAML

    $ haml -f html5 src/views/index.haml index.html

### Sass

(Create a `css/` directory into which the Sass files will be compiled.)

    $ sass -c src/sass/master.sass:css/master.css

## Licence

This software is released under the MIT License.