{nameof, nameofconv, fixlink, isImg} = require '../util'
moment = require 'moment'

format = (cont) ->
    if cont?.attachment?.length > 0
        # TODO: determine attachment type (photo, sticker, invite, voicemail, map, video)
        # For now, just assume it's a photo
        # if cont?.segment?.length > 0
            # href = cont.segment[0]?.link_data?.link_target
            # if isImg href
                # return "Sent a photo"
        return "Sent a photo"
    txt = ""
    for seg, i in cont?.segment ? []
        # TODO: ensure compatibility with proxied message content
        # continue if cont.proxied and i < 1
        if seg.text
            txt += seg.text
        
    return txt

module.exports = view (models) ->
    {conv, entity, viewstate} = models
    clz = ['convlist']
    clz.push 'showconvthumbs' if viewstate.showConvThumbs
    div class:clz.join(' '), ->
        convs = conv.list()
        renderConv = (c) ->
            pureHang = conv.isPureHangout(c)
            lastChanged = conv.lastChanged(c)
            # don't list pure hangouts that are older than 24h
            return if pureHang and (Date.now() - lastChanged) > 24 * 60 * 60 * 1000
            cid = c?.conversation_id?.id
            ur = conv.unread c
            clz = ['conv']
            clz.push "type_#{c.type}"
            clz.push "selected" if models.viewstate.selectedConv == cid
            clz.push "unread" if ur
            clz.push "purehang" if pureHang
            div key:cid, class:clz.join(' '), ->
                part = c?.current_participant ? []
                ents = for p in part when not entity.isSelf p.chat_id
                    entity[p.chat_id]
                name = nameofconv c
                if viewstate.showConvThumbs
                    div class: 'thumbs', ->
                        for p, index in ents
                            break if index >= 2
                            image = p.photo_url
                            unless image
                                entity.needEntity(p.id)
                                image = "images/photo.jpg"
                            img src:fixlink(image), onerror: ->
                                this.src = fixlink("images/photo.jpg")
                div class:'details', ->
                    span class:'convname', name
                    if viewstate.showConvThumbs
                        m = c.event[c.event.length - 1]?.chat_message
                        if m and m.message_content
                            txt = format m.message_content
                            span class:'lastmessage', txt
                # div class:'time', moment(g.start / 1000).calendar()
                if ur > 0 and not conv.isQuiet(c)
                    lbl = if ur >= conv.MAX_UNREAD then "#{conv.MAX_UNREAD}+" else ur + ''
                    span class:'unreadcount', lbl
                div class:'divider'
                if c.typing?.length > 0
                    anyTyping = c.typing.filter((t) -> t?.status == 'TYPING').length
                    tclz = ['convtyping']
                    tclz.push 'animate-growshrink' if anyTyping
                    span class:tclz.join(' '), '⋮'
            , onclick: (ev) ->
                ev.preventDefault()
                action 'selectConv', c

        starred = (c for c in convs when conv.isStarred(c))
        others = (c for c in convs when not conv.isStarred(c))
        div class: 'starred', ->
            div class: 'label', 'Favorites' if starred.length > 0
            starred.forEach renderConv
        div class: 'others', ->
            div class: 'label', 'Recent' if starred.length > 0
            others.forEach renderConv
