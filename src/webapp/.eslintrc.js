module.exports = {
    "extends": "airbnb-base",
    "env": {
        "browser": true,
        "node": true
    },
    "rules": {
        "no-multiple-empty-lines": [1,{"max":3}],
        "no-unused-vars": ["error", { "argsIgnorePattern": "next", "argsIgnorePattern": "req" }],
        "linebreak-style": 0,
      },
    "globals": {
        "app": 1,
        "angular": 1
    }
};