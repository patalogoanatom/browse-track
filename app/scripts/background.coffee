'use strict';

chrome.runtime.onInstalled.addListener (details) ->
  console.log('previousVersion', details.previousVersion)

chrome.browserAction.setBadgeText({text: 0.toString()})

msToTime = (s) ->
  ms = s % 1000

  addZ = (n) ->
    (if n < 10 then '0' else '') + n

  s = (s - ms) / 1000
  secs = s % 60
  s = (s - secs) / 60
  mins = s % 60
  hrs = (s - mins) / 60
  addZ(hrs) + ':' + addZ(mins) + ':' + addZ(secs) + '.' + ms


Stat =
  data: {}
  cur: null

chrome.storage.sync.get 'browser-track.data', (item) ->
  if item['browser-track.data']
    console.log "STORAGE"
    console.log JSON.parse(item['browser-track.data'])
    Stat.data = JSON.parse(item['browser-track.data'])
  
tabChanged = (url) ->
  if Stat.cur
    lst = Stat.data[Stat.cur]
    lst.push(new Date())
  Stat.cur = url
  lst = Stat.data[url] or []
  lst.push(new Date())
  Stat.data[url] = lst

calc = (url)->
  lst =  Stat.data[url]
  if not lst
    return 0
  n = Math.floor (lst.length / 2)
  res = 0
  for i in [0..n]
    if lst[2 * i + 1] and lst[2 * i]
      res += new Date(lst[2 * i + 1]).getTime() - new Date(lst[2 * i]).getTime()
  res += (new Date()).getTime() - lst[lst.length - 1].getTime()
  return res

updateBadge = (url)->
  res = calc url
  chrome.browserAction.setBadgeText({text: msToTime(res)})


chrome.tabs.onActivated.addListener (activeInfo)->
  console.log "Select #{activeInfo.tabId} "
  Stat.curTabId = activeInfo.tabId
  chrome.tabs.get activeInfo.tabId, (tab) ->
    if tab.url
      url = new URL(tab.url)
      if url.protocol == 'https:' || url.protocol == 'http:'
        tabChanged url.hostname
        updateBadge url.hostname
      else
        chrome.browserAction.setBadgeText({text: ""})

chrome.alarms.onAlarm.addListener (alarm)->
  console.log alarm, Stat.curTabId
  if alarm.name == "update"
    if not Stat.curTabId
      return
    chrome.tabs.get Stat.curTabId, (tab)->
      if tab.url
        url = new URL(tab.url)
        if url.protocol == 'https:' || url.protocol == 'http:'
          updateBadge url.hostname
    chrome.storage.sync.set {'browser-track.data': JSON.stringify(Stat.data)}

chrome.alarms.create("update", {periodInMinutes: 0.0166})
console.log('\'Allo \'USER! Made by Madik Event Page for Browser Action')


chrome.runtime.onInstalled.addListener (details) ->
  console.log 'previousVersion', details.previousVersion