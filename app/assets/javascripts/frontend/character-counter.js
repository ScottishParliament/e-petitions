document.addEventListener('DOMContentLoaded', function(event) {
  'use strict';

  var updateCounter = function() {
    var counter = this.nextElementSibling,
        contents = this.value,
        charCount = contents.length,
        maxCharCount = parseInt(this.dataset.maxLength),
        charsRemaining = maxCharCount - charCount;

    counter.textContent = charsRemaining;
    counter.classList.toggle('too-many-characters', charsRemaining < 0);
  }

  var attachCounter = function() {
    var textareas = document.querySelectorAll('textarea[data-max-length]');

    for (var i = 0; i < textareas.length; i++) {
      var textarea = textareas[i],
          ariaId = 'char-count-' + textarea.id,
          counter = textarea.nextElementSibling;

      counter.setAttribute('role', 'status');
      counter.setAttribute('aria-live', 'polite');
      counter.setAttribute('aria-relevant', 'text');
      counter.setAttribute('id', ariaId);
      textarea.setAttribute('aria-controls', ariaId);

      updateCounter.apply(textarea);

      textarea.addEventListener('change', updateCounter);
      textarea.addEventListener('keyup', updateCounter);
      textarea.addEventListener('paste', updateCounter);
    }
  }

  var characterCounter = function() {
    attachCounter();
  }

  window.GOVUK = window.GOVUK || {};
  window.GOVUK.PETS = window.GOVUK.PETS || {};
  GOVUK.PETS.characterCounter = characterCounter;
});
