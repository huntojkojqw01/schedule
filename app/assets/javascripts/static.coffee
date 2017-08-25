# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on 'turbolinks:load',()->
	$("#loading").hide()
	$('form').on 'ajax:send',(event, xhr, status, error)->
	  $("#loading").show()
	$('form').on 'ajax:success',(event, xhr, status, error)->
	  $("#loading").hide()
