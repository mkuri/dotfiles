module.exports = {
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'chore', 'docs', 'refactor', 'test', 'ci', 'perf', 'style'],
    ],
    'type-empty': [2, 'never'],
    'subject-empty': [2, 'never'],
  },
};
