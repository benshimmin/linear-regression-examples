# A simple set of classes which generate a line of best fit using linear
# regression, and allow the line and points to be plotted by multiple renderers.
#
# The code is, to a great or lesser extent, similar to to the observer pattern;
# the engine represents the subject and the renderers are the observers.

# Return the last element in an Array
Array::last = -> @[@.length - 1]

# An abstract representation of a point.
class Point

    constructor : (@x, @y) ->
        @colour = (Math.floor(Math.random() * 0xffffff)).toString 16

    # useful string representation when working with SVG
    toString : => "#{@x},#{@y}"

# The Engine class takes care of generating the line of best fit and keeps
# track of both the points being created and the renderers which plot the
# points.
class Engine

    constructor : ->
        @renderers = []
        @width     = 600
        @height    = 500

        # mode may either be "colour" or "wireframe"
        @mode      = "colour"

        # this holds the engine's points
        @points    = []

        @generateRandomPoints()

    # make 20 random points
    generateRandomPoints : () =>
        for i in [0..20]
            @points.push new Point(
                Math.random() * @width,
                Math.random() * @height
            )

        @points

    # add a new point to the engine and then inform the renderers that
    # they must redraw
    addPoint : (x, y) =>
        @points.push new Point(x, y)

        @iterate "redraw"

    # generate a line of best fit using linear regression. A good explanation
    # of the formula can be found here:
    #
    #   http://easycalculation.com/statistics/learn-regression.php
    getLine : =>
        @len  = @points.length

        sumX  = 0
        sumY  = 0
        sumXY = 0
        sumX2 = 0

        sumX  += point.x for point in @points
        sumY  += point.y for point in @points
        sumXY += point.x * point.y for point in @points
        sumX2 += point.x * point.x for point in @points

        denominator = (@len * sumX2)  - (sumX * sumX)

        intercept   = ((sumY * sumX2) - (sumX * sumXY)) / denominator
        slope       = ((@len * sumXY) - (sumX * sumY))  / denominator

        getPoint = (x) => new Point x, intercept + x * slope

        # return an object with a start and end point
        start : getPoint(0), end : getPoint(@width)

    # destructor
    clear : =>
        @points = []

        @iterate "clear"

    # create more random points
    generate : =>
        @generateRandomPoints()

        @iterate "regenerate"

    # change between "colour" and "wireframe"
    setRenderingMode : (mode) =>
        @mode = mode

        @iterate "clear"
        @iterate "regenerate"

    # iterate over the renderers, calling a function on each
    iterate : (fn) => renderer[fn]() for renderer in @renderers


# An abstract renderer - common functionality shared between renderers,
# regardless of the specifics of their implementation
class Renderer

    init : =>
        @render()
        @listen()

    render : =>
        @redraw()

    # bind event listeners to achieve the drag effect
    listen : =>

        @canvas.on "mousedown", (event) => @canvas.on "mousemove", @drag
        $(window).on "mouseup", => @canvas.off "mousemove"

    # when the checkbox is ticked, dispatch to the engine the coordinates
    # of the drag so the engine can add a new point
    drag : (event) =>
        return unless $("#cb_click_to_add").is ":checked"

        # if we have event.offsetX...
        if typeof event.offsetX isnt "undefined"
            engine.addPoint event.offsetX, event.offsetY
        else
        # otherwise (eg. Firefox) simulate it
            offset = $(event.target).offset()

            engine.addPoint(
                event.pageX - offset.left,
                event.pageY - offset.top
            )

    regenerate : => @redraw()


# Concrete renderer implementation for Raphaël.
class RaphaelRenderer extends Renderer

    constructor : (target) ->
        # Raphaël's canvas
        @paper  = Raphael target
        # offset width and height by a pixel
        @width  = @paper.width  - 1
        @height = @paper.height - 1

        @init()

    drawAxes : =>
        @paper.path "M1,#{@height}L#{@width},#{@height}"
        @paper.path "M1,1L1,#{@width}"

    render : =>
        @drawPoints false, "wireframe"
        @drawBestFit()
        @drawAxes()
        @addBG()

    # draw a background so that we may have something to click on
    addBG : =>
        bg = @paper.rect(0, 0, @width, @height).attr(
            "stroke" : "none",
            "fill" : "#ffffff"
        ).toBack()

        @canvas = $(bg.node)

    redraw : =>
        @drawPoints true
        @drawBestFit()

    # This is the main difference between Raphaël and canvas: in the latter
    # we need to do a redraw of the canvas each time we add a new point
    # (and change the line of best fit), whereas with Raphaël, we only
    # necessarily need to add *one* new point and then remove and redraw the
    # line of best fit.
    #
    # Using the `redraw` Boolean, we can determine whether we are doing a
    # partial redraw (just adding the last new point), or a complete redraw
    # (adding many points).
    drawPoints : (redraw = true) =>
        for point in (if redraw then [engine.points.last()] else engine.points)
            if engine.mode is "colour"
                attrs = "stroke" : "none", "fill" : "#" + point.colour

            @paper.circle(point.x, point.y, 5).attr attrs

    # redraw the line of best fit, removing it first if it already exists
    drawBestFit : =>
        # SVG doesn't like a line two have fewer than two points (funny, that)
        return if engine.points.length < 2

        @line.remove() if @line

        bestFit = engine.getLine()
        @line = @paper.path \
        "M#{bestFit.start.toString()}L#{bestFit.end.toString()}"

    regenerate : =>
        @clear()
        @drawPoints false
        @drawBestFit()

    # clear the paper
    clear : =>
        @paper.clear()
        @addBG()
        @listen()
        @drawAxes()


# Concrete renderer implementation for HTML5 canvas.
class CanvasRenderer extends Renderer

    constructor : (target) ->
        @canvas  = $(target)
        @context = @canvas[0].getContext "2d"
        @width   = @canvas.width()
        @height  = @canvas.height()

        @init()

    drawAxes : =>
        @path new Point(0, 0), new Point(0, @width)
        @path new Point(0, @height), new Point(@width, @height)

    # clear the canvas, draw the points, and then draw the line of best fit
    redraw : =>
        @clear()
        @drawPoints()
        @drawBestFit()

    drawPoints : =>
        @circle(point.x, point.y, 5, point.colour) for point in engine.points

    drawBestFit : =>
        bestFit = engine.getLine()
        @path bestFit.start, bestFit.end

    # helper method to draw lines more easily
    path : (startPoint, endPoint) =>
        @context.beginPath()
        @context.moveTo startPoint.x, startPoint.y
        @context.lineTo endPoint.x, endPoint.y
        @context.closePath()
        @context.stroke()

    # helper method to draw circles more easily
    circle : (x, y, radius, colour) =>
        @context.beginPath()
        @context.arc x, y, radius, 0, Math.PI * 2, false
        if engine.mode is "colour"
            @context.fillStyle = "#" + colour
            @context.fill()
        else
            @context.stroke()
        @context.closePath()

    # clear the canvas
    clear : =>
        @context.clearRect 0, 0, @width, @height
        @drawAxes()


# These objects are scoped globally (within the CoffeeScript enclosure).

# One engine...
engine    = new Engine

# ...and many renderers.
renderers =
    Canvas  : CanvasRenderer
    Raphael : RaphaelRenderer


# Initialise everything on JQuery's DOM ready.
$ ->
    # add renderers to the engine
    engine.renderers = [
        new renderers.Canvas("canvas"),
        new renderers.Raphael("canvas")
    ]

    # simple events triggered via the form options - all communication
    # is via the engine
    $("#clear").on "click", => engine.clear()

    $("#generate").on "click", => engine.generate()

    $("#sel_render").on "change", =>
        engine.setRenderingMode $("#sel_render").val()
