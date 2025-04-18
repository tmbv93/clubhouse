import {Controller} from '@hotwired/stimulus'
import {useClickOutside} from 'stimulus-use'

export default class extends Controller {
    static targets = ['menu']

    connect() {
        useClickOutside(this, {element: this.menuTarget})
    }

    clickOutside(event) {
        this.close(event)
    }

    toggle(event) {
        event.stopPropagation();
        this.menuTarget.open ? this.close(event) : this.open(event)
    }

    open(event) {
        event.preventDefault()
        this.menuTarget.show()
    }

    close(event) {
        event.preventDefault()
        this.menuTarget.close()
    }
}
