'use strict'

angular.module('graphwikiApp')
	.controller 'MainCtrl', ($scope) ->
		$scope.awesomeThings = [
			'HTML5 Boilerplate'
			'AngularJS'
			'Karma'
		]

		
		#
		#  main.js
		#
		#  A project template for using arbor.js
		#
		Renderer = (canv) ->
			canvas = $(canv).get(0)
			ctx = canvas.getContext("2d")
			particleSystem = undefined
			that =
				init: (system) ->
					
					#
					# the particle system will call the init function once, right before the
					# first frame is to be drawn. it's a good place to set up the canvas and
					# to pass the canvas size to the particle system
					#
					# save a reference to the particle system for use in the .redraw() loop
					particleSystem = system
					
					# inform the system of the screen dimensions so it can map coords for us.
					# if the canvas is ever resized, screenSize should be called again with
					# the new dimensions
					particleSystem.screenSize canvas.width, canvas.height
					particleSystem.screenPadding 80 # leave an extra 80px of whitespace per side
					
					# set up some event handlers to allow for node-dragging
					that.initMouseHandling()
					return

				redraw: ->
					
					# 
					# redraw will be called repeatedly during the run whenever the node positions
					# change. the new positions for the nodes can be accessed by looking at the
					# .p attribute of a given node. however the p.x & p.y values are in the coordinates
					# of the particle system rather than the screen. you can either map them to
					# the screen yourself, or use the convenience iterators .eachNode (and .eachEdge)
					# which allow you to step through the actual node objects but also pass an
					# x,y point in the screen's coordinate system
					# 
					ctx.fillStyle = "white"
					ctx.fillRect 0, 0, canvas.width, canvas.height
					particleSystem.eachEdge (edge, pt1, pt2) ->
						
						# edge: {source:Node, target:Node, length:#, data:{}}
						# pt1:  {x:#, y:#}  source position in screen coords
						# pt2:  {x:#, y:#}  target position in screen coords
						
						# draw a line from pt1 to pt2
						ctx.strokeStyle = "rgba(0,0,0, .333)"
						ctx.lineWidth = 1
						ctx.beginPath()
						ctx.moveTo pt1.x, pt1.y
						ctx.lineTo pt2.x, pt2.y
						ctx.stroke()
						return

					particleSystem.eachNode (node, pt) ->
						
						# node: {mass:#, p:{x,y}, name:"", data:{}};
						# pt:   {x:#, y:#}  node position in screen coords
						
						# draw a rectangle centered at pt
						w = 10
						ctx.fillStyle = (if (node.data.alone) then "orange" else "black")
						ctx.fillRect pt.x - w / 2, pt.y - w / 2, w, w
						return

					return

				initMouseHandling: ->
					
					# no-nonsense drag and drop (thanks springy.js)
					dragged = null
					
					# set up a handler object that will initially listen for mousedowns then
					# for moves and mouseups while dragging
					handler =
						clicked: (e) ->
							pos = $(canvas).offset()
							_mouseP = arbor.Point(e.pageX - pos.left, e.pageY - pos.top)
							dragged = particleSystem.nearest(_mouseP)
							
							# while we're dragging, don't let physics move the node
							dragged.node.fixed = true  if dragged and dragged.node isnt null
							$(canvas).bind "mousemove", handler.dragged
							$(window).bind "mouseup", handler.dropped
							false

						dragged: (e) ->
							pos = $(canvas).offset()
							s = arbor.Point(e.pageX - pos.left, e.pageY - pos.top)
							if dragged and dragged.node isnt null
								p = particleSystem.fromScreen(s)
								dragged.node.p = p
							false

						dropped: (e) ->
							return  if dragged is null or dragged.node is `undefined`
							dragged.node.fixed = false  if dragged.node isnt null
							dragged.node.tempMass = 1000
							dragged = null
							$(canvas).unbind "mousemove", handler.dragged
							$(window).unbind "mouseup", handler.dropped
							_mouseP = null
							false

					
					# start listening
					$(canvas).mousedown handler.clicked

			that

		$(document).ready ->
			sys = arbor.ParticleSystem(1000, 600, 0.5) # create the system with sensible repulsion/stiffness/friction
			sys.parameters gravity: true
			# use center-gravity to make the graph settle nicely (ymmv)
			sys.renderer = Renderer("#viewport") # our newly created renderer will have its .init() method called shortly by sys...
			
			# add some nodes to the graph and watch it go...
			sys.addEdge "a", "b"
			sys.addEdge "a", "c"
			sys.addEdge "a", "d"
			sys.addEdge "a", "e"
			sys.addNode "f",
				alone: true
				mass: 0.25


			# or, equivalently:
			#
			# sys.graft({
			#   nodes:{
			#     f:{alone:true, mass:.25}
			#   }, 
			#   edges:{
			#     a:{ b:{},
			#         c:{},
			#         d:{},
			#         e:{}
			#     }
			#   }
			# })

