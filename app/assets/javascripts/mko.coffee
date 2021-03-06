$(document).ready ->
  window.loading = true

  window.onpopstate = (event) ->
    was = document.location
    tipo = if event.state && event.state.tipo then event.state.tipo else ''
    wo = if tipo == 'filme' then 'meta' else 'meio'
    $("##{wo}").load("##{was}")

  $(document).ajaxStart -> $('#loading').fadeIn(300)
  $(document).ajaxStop -> $('#loading').fadeOut(300, -> updateTriggers())

  $('#menu').fadeIn(5000)
  $('#info').fadeIn(1000)

  updateTriggers = ->
    $('.capa').click ->
      id = $(this).attr('id')
      urlized = '/filme/' + $(this).attr('urlized')
      titulo = $(this).children().next().text()
      $("#meta").load urlized, (data) ->
        #$(data).appendTo
        document.title = "Acervo MKO ❤ #{titulo}"
        history.pushState({ tipo: 'filme' }, '', urlized)

    # todo: mudar compormento em tablets - sem opacidade - pois não há MouseMove
    $('.capa>img')
      .on 'mouseenter', -> $(this).animate(opacity: 1, 200)
      .on 'mouseleave', -> $(this).animate(opacity: 0.3, 200)
      .load -> $(this).fadeIn 1500
      .error -> $(this).attr('src', 'http://extrapolo.com/assets/capas/00.jpg')

    # em 3 segundos exibe todas as capas e libera carregar próximas páginas
    setTimeout ->
      $("img").fadeIn(800)
      window.loading = false
    , 3000

  $('.logo').on 'click', (e) -> window.location = '/'

  $('.border').on 'click', (e) ->
    e.preventDefault()
    cor = $(this).attr('cor');
    count = $(this).attr('count');
    urlized = "/status/#{cor}"
    $('#meio').load urlized, ->
      $('#info').remove()
      history.pushState({ tipo: 'status' }, '', urlized)
      updateTriggers()
      #todo: not enought for /status pagination.
      window.to_load = parseInt(count)


  $(document).scroll ->
    # carrega próximas páginas se já não estiver carregando, ainda há mais para carregar e scroll está no fim da página
    return if !window.loading && (window.to_load > $('.capa').size()) && ($(window).scrollTop() > $(document).height() - $(window).height() - 50)
      window.loading = true
      metainfo = $('.metainfo').last()
      page = parseInt(metainfo.attr('page')) + 1
      tipo = metainfo.attr('tipo')
      tipo_id = metainfo.attr('tipo_id')
      $.get "/list/#{tipo}/#{tipo_id}?page=#{page}", (data) ->
        $(data).appendTo("#meio")
        updateTriggers()

  # setup autocompletes
  fields = ['director', 'country', 'genre', 'movie']
  termTemplate = "<span class='ui-autocomplete-term'>%s</span>";
  $.each fields, (i, tipo) ->
    $("##{tipo}").autocomplete
      minLength: 2
      delay: 200
      source: (request, response) ->
        $.getJSON "/autocomplete.json?tipo=#{tipo}&nome=" + request.term, (data) -> response data
      select: (e, ui) ->
        $('#info').fadeOut(300)
        window.scrollTo 0, 0 # go to top
        count = ui.item.count
        others = fields.filter (t) -> t != tipo
        urlized = "/list/#{tipo}/#{ui.item.id}"
        $.each others, (i, tipo) -> $("##{tipo}").val('') # limpa outros campos
        $('#meio').load urlized, ->
          history.pushState({ tipo: tipo }, '', urlized)
          document.title = "Acervo MKO ❤ #{ui.item.label}"
          window.to_load = parseInt(count)
          updateTriggers()

    .data("ui-autocomplete")._renderItem = (ul, item) ->
      tipo = $(document.activeElement).attr('id')
      if item.count == 1 # singular
        count_title = if tipo == 'movie' then 'peer' else 'filme'
      else
        count_title = if tipo == 'movie' then 'peers' else 'filmes'
      # todo: negritar termo
      $("<li>").append("<a>#{item.value}<p class='sub'>#{item.count} #{count_title}</p></a>").appendTo ul

  # todo: filtrar por ano

  # $("#anos-range").slider
  #   range: true
  #   min: 1892
  #   max: 2014
  #   values: [1940, 1980]
  #   slide: (event, ui) -> updateAnos()

  # updateAnos = -> $("#ano").text $("#anos-range").slider("values", 0) + " - " + $("#anos-range").slider("values", 1)
  # updateAnos()

  updateTriggers()
