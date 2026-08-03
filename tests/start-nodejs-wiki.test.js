'use strict';

const assert = require('node:assert/strict');
const { protectExcludedPluginsFromFilesystemSync } = require('../start-nodejs-wiki');

let postStartHook;
const savedTitles = [];
const deletedTitles = [];
const fileInfo = { filepath: '/wiki/tiddlers/editor.tid' };
const syncadaptor = {
  name: 'filesystem',
  boot: {
    files: {
      '$:/plugins/example/editor': fileInfo,
    },
  },
  getTiddlerInfo() {
    return fileInfo;
  },
  saveTiddler(tiddler, callback) {
    savedTitles.push(tiddler.fields.title);
    callback(null, fileInfo);
  },
  deleteTiddler(title, callback) {
    deletedTitles.push(title);
    callback(null, null);
  },
};
const tiddlyWiki = {
  hooks: {
    addHook(name, callback) {
      assert.equal(name, 'th-server-command-post-start');
      postStartHook = callback;
    },
  },
  syncadaptor,
  wiki: {
    filterTiddlers(filter) {
      assert.equal(filter, '[[$:/plugins/example/editor]]');
      return ['$:/plugins/example/editor'];
    },
  },
};

protectExcludedPluginsFromFilesystemSync(tiddlyWiki, '[[$:/plugins/example/editor]]');
postStartHook();

syncadaptor.saveTiddler(
  { fields: { title: '$:/plugins/example/editor' } },
  (error, adaptorInfo) => {
    assert.equal(error, null);
    assert.equal(adaptorInfo, fileInfo);
  },
  {},
);
syncadaptor.deleteTiddler(
  '$:/plugins/example/editor',
  (error, adaptorInfo) => {
    assert.equal(error, null);
    assert.equal(adaptorInfo, fileInfo);
  },
  {},
);
syncadaptor.saveTiddler(
  { fields: { title: 'Runtime Comment' } },
  () => {},
  {},
);
syncadaptor.deleteTiddler('Runtime Comment', () => {}, {});

assert.deepEqual(savedTitles, ['Runtime Comment']);
assert.deepEqual(deletedTitles, ['Runtime Comment']);
console.log('start-nodejs-wiki tests passed');
