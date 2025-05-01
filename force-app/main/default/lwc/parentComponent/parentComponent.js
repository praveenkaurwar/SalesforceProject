import { LightningElement, api, track, wire } from 'lwc';
export default class ParentComponent extends LightningElement {
  @track count = 1;

  handlealert(event){
        console.log('log---> '+ this.count);
        console.log('log---> '+ event.detail.number);
        this.count += event.detail.number;
        const callChild = this.template.querySelector('c-practice-l-w-c');
        callChild.showBanner('Success', 'Runninggggggggggg', 'success');
  }


}