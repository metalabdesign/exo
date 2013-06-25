namespace 'Exo.Views', (exports) ->
  class exports.Datepicker extends Exo.View
    className: "datepicker"
    hidden: false
    autoRender: true
    headerFormat: "MMMM YYYY"
    dateFormat: "MM/DD/YYYY"
    firstDayOfWeek: 1
    linkTemplate: null

    position:
      my: 'left top',
      at: 'left bottom',
      collision: 'fit'

    events:
      "mouseup .datepicker-prev": (e) ->
        e.preventDefault()
        @prev()

      "mouseup .datepicker-next": (e) ->
        e.preventDefault()
        @next()

      "mouseup .day": (e) ->
        e.preventDefault()
        @select(e.target.getAttribute("data-datestamp"))

    initialize: ->
      @range = []
      @el.id = @id = 'dp-' + new Date().getTime()

      if @hidden then @$el.hide() else this.$el.show()

      @now = moment()
      @visible = false
      @render() if @autoRender

    render: ->
      @$el.empty()

      @$header = $('<div class="datepicker-header"></div>')
      @$body = $('<div class="datepicker-body"></div>')

      @renderHeader()
      @renderBody()

      @$el.append(@$header).append(@$body)

    renderHeader: ->
      prevBtn = document.createElement('a')
      prevBtn.className = 'datepicker-prev'

      nextBtn = document.createElement('a')
      nextBtn.className = 'datepicker-next'

      @monthHeader = $('<div class="datepicker-title">' + @now.format(@headerFormat) + '</div>')

      dayLabels = _.map(["Sun", "Mon", "Tue", "Wed", "Thurs", "Fri", "Sat"], (str) -> '<span>' + str.substr(0, 1) + '</span>')
      dayLabels = dayLabels.concat(dayLabels.splice(0, @firstDayOfWeek))
      $(document.createElement("div"))
            .addClass('datepicker-header-inner')
            .append(prevBtn)
            .append(this.monthHeader)
            .append(nextBtn)
            .append('<div class="datepicker-daysofweek">' + dayLabels.join('') + '</div>')
            .appendTo(@$header)

      @$header

    renderBody: ->
      today = moment()
      d = moment(@now).date(1)

      # If the first day of the month is early in the week, draw the week before.
      firstDay = moment(d).day(@firstDayOfWeek).add('days', 3)
      if firstDay.toDate() > d.toDate()
        d.subtract('days', 7)

      d = d.day(@firstDayOfWeek)

      @range[0] = moment(d)
      @$body.empty()

      for j in [0..5]
        for i in [0..6]
          classes = ['day']

          classes.push('first') if i == 0
          classes.push('last')  if i == 6

          if @now.month() != d.month()
            classes.push('not-in-month')

          if (today.toDate().toLocaleDateString() == d.toDate().toLocaleDateString())
            classes.push('today')

           E = $(document.createElement('a')).attr({
            'data-datestamp': d.format(@dateFormat),
            'class': classes.join(' ')
          }).html(d.date())

          E.appendTo(@$body)
          d.add('days', 1)

      @range[1] = d.clone()

      @$body

    showDate: (date) ->
      @now = moment(date) if date

      @monthHeader.html(@now.format(@headerFormat))
      @renderBody()

    prev: ->
      this.now.subtract('month', 1)
      this.showDate()

    next: ->
      this.now.add('month', 1)
      this.showDate()

    show: ->
      this.visible = true
      this.$el.show().position(@position)
      this.trigger('show')

    hide: ->
      this.visible = false
      this.$el.hide()
      this.trigger('hide')

    select: (date, options) ->
      date = moment(date) if _.isString(date)

      options = _.extend({ silent: false, toggle: true }, options)

      if date.format(@dateFormat) != @now.format(@dateFormat)
        @showDate(date)

      @clear() if(options.toggle)

      elem = @$body.find('[data-datestamp="' + date.format(@dateFormat) + '"]').addClass('highlight')

      if !options.silent
        @trigger('select', date, elem)

      this

    selectRange: (date1, date2, options) ->
      options = _.extend({ silent: false, toggle: true }, options)

      this.clear() if options.toggle

      if(date1 == date2)
        @select(date1, options)
      else
        date1 = date1.clone()
        date2 = date2.clone()
        options.toggle = false

        while date1 <= date2
          @select(date1, options)
          date1.setDate(date1.getDate() + 1)

    clear: ->
      @trigger('clear')
      @$body.children().removeClass('highlight')
