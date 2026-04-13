/**
 * EmptyState component - renders an empty state UI for lists with no data
 *
 * Props:
 * - title: string (required)
 * - description: string (required)
 * - actionButton?: { label: string, onClick: () => void } (optional)
 */

export function createEmptyState({ title, description, actionButton }) {
  const container = document.createElement('div');
  container.className = 'empty-state';

  const titleEl = document.createElement('h2');
  titleEl.className = 'empty-state-title';
  titleEl.textContent = title;
  container.appendChild(titleEl);

  const descEl = document.createElement('p');
  descEl.className = 'empty-state-description';
  descEl.textContent = description;
  container.appendChild(descEl);

  if (actionButton) {
    const buttonEl = document.createElement('button');
    buttonEl.type = 'button';
    buttonEl.className = 'empty-state-action';
    buttonEl.textContent = actionButton.label;
    buttonEl.addEventListener('click', actionButton.onClick);
    container.appendChild(buttonEl);
  }

  return container;
}

export default createEmptyState;
