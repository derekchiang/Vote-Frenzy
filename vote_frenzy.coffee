Options = new Meteor.Collection "options"
Topics = new Meteor.Collection "topics"

if Meteor.isClient
  Meteor.Router.add
    '/': 'index',
    '/vote/:id': (id) ->
      Session.set 'voteId', id
      return 'board'

  Template.board.options = ->
    return Options.find {voteId: Session.get 'voteId'},
      sort:
        votes: -1,
        index: 1

  Template.board.topic = ->
    return Topics.findOne {voteId: Session.get 'voteId'}

  Template.board.selected_option = ->
    option = Options.findOne Session.get 'selected_option'
    return option and option.text

  Template.option.selected = ->
    return if (Session.equals 'selected_option', @._id) then 'selected' else ''

  Template.board.events
    'click input.inc': ->
      Options.update (Session.get 'selected_option'), {
        $inc:
          votes: 1
      }

  Template.option.events
    'click': ->
      Session.set 'selected_option', @._id

  Template.index.events
    'click input#submit': ->
      isValidTopic = (topic) ->
        return topic.length > 0

      isValidOption = (option) ->
        return option.length > 0

      if isValidTopic $('#topic').val()
        $('#topic-warning').hide()
        allOptionsValid = true
        for optionInput, i in $('.option')
          unless isValidOption $(optionInput).val()
            $("#option-warning-#{i+1}").show()
            allOptionsValid = false
          else
            $("#option-warning-#{i+1}").hide()

        if allOptionsValid
          voteId = Random.id()
          for optionInput, i in $('.option')
            Options.insert
              text: $(optionInput).val(),
              index: i,
              voteId: voteId,
              votes: 0

          Topics.insert
            text: $('#topic').val(),
            voteId: voteId

          Meteor.Router.to "/vote/#{voteId}"

      else
        $('#topic-warning').show()
    
    'click input#add-option': ->
      options = Session.get 'options'
      options.push ''
      Session.set 'options', options

    # Save options
    'blur input.option': ->
      options = []
      for optionInput in $('.option')
        options.push $(optionInput).val()
      
      Session.set 'options', options

  Template.option_list.options = ->
    Session.setDefault 'options', ['']
    Session.get 'options'

  Handlebars.registerHelper 'iter_options', (options, block) ->
    acc = ''
    for text, i in options
      acc += block.fn
        index: i + 1
        text: text
    return acc


if Meteor.isServer
  Meteor.startup ->
    if Options.find().count() == 0
      options = [
        "Ada Lovelace", 
        "Grace Hopper", 
        "Marie Curie", 
        "Carl Friedrich Gauss", 
        "Nikola Tesla", 
        "Claude Shannon"
      ]

      for option in options
        Options.insert
          text: option
          votes: (Math.floor Random.fraction() * 10) * 5