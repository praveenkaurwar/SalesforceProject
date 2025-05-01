import { LightningElement, api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent'
export default class PracticeLWC extends LightningElement {
   
   handleClick(event){
    const newalert = new CustomEvent('alert', {
        detail: {number : 2}
    });
    this.dispatchEvent(newalert);
   }

   @api
   showBanner(title, message, variant){
       const showEvent = new ShowToastEvent({
        title : title,
        message : message,
        variant : variant

       });
       this.dispatchEvent(showEvent);
   }
}