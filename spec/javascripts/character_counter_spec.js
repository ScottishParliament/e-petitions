describe('Character counter', function() {
  var $textbox,
      $counter;

  beforeEach(function () {
    $textbox = document.createElement('textarea');
    $textbox.id = 'fixture';
    $textbox.dataset.maxLength = '50';

    $counter = document.createElement('p');
    $counter.className = 'character-count';
    $counter.textContent = '50 characters max';

    document.body.appendChild($textbox);
    document.body.appendChild($counter);
  });

  afterEach(function () {
    document.body.removeChild($textbox);
    document.body.removeChild($counter);
  });

  describe("When called", function () {
    it("Puts the max characters into the character counter", function () {
      GOVUK.PETS.characterCounter();
      expect($counter.textContent).toEqual('50');
    });

    it("Adds an id to the character counter based on the textbox id", function () {
      GOVUK.PETS.characterCounter();
      expect($counter.id).toEqual('char-count-' + $textbox.id);
    });

    it("Adds an aria-controls attribute to the textbox linking it to the character counter", function () {
      GOVUK.PETS.characterCounter();
      expect($textbox.attributes['aria-controls'].value).toEqual($counter.id);
    });

    it("Sets the count to what's in the data-max-length attribute on the textbox", function () {
      $textbox.dataset.maxLength = '40';
      GOVUK.PETS.characterCounter();
      expect($counter.textContent).toEqual('40');
    });

    it("Gives the correct character count for a textbox that has content when the page loads", function () {
      $textbox.value = 'Words entered';
      GOVUK.PETS.characterCounter();
      expect($counter.textContent).toEqual('37');
    });
  });

  describe("When content is added to the textbox", function () {
    it("Has the correct character count if some characters are entered by keyup event", function () {
      GOVUK.PETS.characterCounter();
      $textbox.value = 'Word entered';
      $textbox.dispatchEvent(new KeyboardEvent('keyup'));
      expect($counter.textContent).toEqual('38');
    });

    it("Has the correct character count if some words are entered by paste event", function () {
      GOVUK.PETS.characterCounter();
      $textbox.value = 'Words entered';
      $textbox.dispatchEvent(new ClipboardEvent('paste'));
      expect($counter.textContent).toEqual('37');
    });

    it("Has the correct character count if some words are entered by change event", function () {
      GOVUK.PETS.characterCounter();
      $textbox.value = 'Words entered';
      $textbox.dispatchEvent(new Event('change'));
      expect($counter.textContent).toEqual('37');
    });

    it("Has the correct character count if a single character is entered", function () {
      GOVUK.PETS.characterCounter();
      $textbox.value = 'w';
      $textbox.dispatchEvent(new KeyboardEvent('keyup'));
      expect($counter.textContent).toEqual('49');
    });

    it("Has the correct character count if 50 characters are entered", function () {
      GOVUK.PETS.characterCounter();
      $textbox.value = 'Vestibulum vel eleifend nunc. Aliquam fermentum nu';
      $textbox.dispatchEvent(new KeyboardEvent('keyup'));
      expect($counter.textContent).toEqual('0');
    });

    it("Has the correct character count if 51 characters are entered", function () {
      GOVUK.PETS.characterCounter();
      $textbox.value = 'Vestibulum vel eleifend nunc. Aliquam fermentum num';
      $textbox.dispatchEvent(new KeyboardEvent('keyup'));
      expect($counter.textContent).toEqual('-1');
    });

    it("Has the correct character count if 52 characters are entered", function () {
      GOVUK.PETS.characterCounter();
      $textbox.value = 'Vestibulum vel eleifend nunc. Aliquam fermentum numb';
      $textbox.dispatchEvent(new KeyboardEvent('keyup'));
      expect($counter.textContent).toEqual('-2');
    });
  });
});
