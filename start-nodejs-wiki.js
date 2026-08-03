'use strict';

function protectExcludedPluginsFromFilesystemSync(tiddlyWiki, excludedPluginsFilter) {
  if (!excludedPluginsFilter) {
    return;
  }

  tiddlyWiki.hooks.addHook('th-server-command-post-start', function() {
    const syncAdaptor = tiddlyWiki.syncadaptor;
    if (!syncAdaptor || syncAdaptor.name !== 'filesystem') {
      return;
    }

    const excludedTitles = new Set(tiddlyWiki.wiki.filterTiddlers(excludedPluginsFilter));
    const saveTiddler = syncAdaptor.saveTiddler.bind(syncAdaptor);
    const deleteTiddler = syncAdaptor.deleteTiddler.bind(syncAdaptor);

    syncAdaptor.saveTiddler = function(tiddler, callback, options) {
      if (excludedTitles.has(tiddler.fields.title)) {
        callback(null, syncAdaptor.getTiddlerInfo(tiddler));
        return;
      }
      saveTiddler(tiddler, callback, options);
    };

    syncAdaptor.deleteTiddler = function(title, callback, options) {
      if (excludedTitles.has(title)) {
        callback(null, syncAdaptor.boot.files[title]);
        return;
      }
      deleteTiddler(title, callback, options);
    };
  });
}

function startNodeJSWiki() {
  const tiddlyWikiBootModule = process.env.TIDDLYWIKI_BOOT_MODULE || '/usr/local/lib/node_modules/tiddlywiki/boot/boot.js';
  const { TiddlyWiki } = require(tiddlyWikiBootModule);
  const tiddlyWiki = TiddlyWiki();

  tiddlyWiki.boot.extraPlugins = ['plugins/tiddlywiki/tiddlyweb'];
  protectExcludedPluginsFromFilesystemSync(tiddlyWiki, process.env.EXCLUDED_PLUGINS_FILTER || '');
  tiddlyWiki.boot.argv = process.argv.slice(2);
  tiddlyWiki.boot.boot();
}

if (require.main === module) {
  startNodeJSWiki();
}

module.exports = {
  protectExcludedPluginsFromFilesystemSync,
  startNodeJSWiki,
};
