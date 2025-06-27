import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getShipmentRequests from '@salesforce/apex/ShipmentRequestController.getShipmentRequests';
import updateShipmentRequest from '@salesforce/apex/ShipmentRequestController.updateShipmentRequest';

import PlatformEventSubscriber from './platformEventSubscriber';

const COLUMNS = {
    Name: { label: 'ShipmentRequest Number', fieldName: 'Name', type: 'url' },
    Destination__c: { label: 'Destination', fieldName: 'Destination__c', type: 'text' },
    Carrier__c: { label: 'Carrier', fieldName: 'Carrier__c', type: 'text' },
    Status__c: { label: 'Status', fieldName: 'Status__c', type: 'text' },
    Tracking_ID__c: { label: 'Tracking ID', fieldName: 'Tracking_ID__c', type: 'text' },
    Estimated_Delivery__c: { label: 'Estimated Delivery', fieldName: 'Estimated_Delivery__c', type: 'date' }
};

const STATUS_COLORS = {
    'Assigned to Agent': '#ACF3E4',
    'In Review': '#F9E3B6',
    'Ready for Dispatch': ''
};
const ICONS = {
    Status__c: {
        'In Review': 'utility:preview'
    }
};

const CHANNEL_NAME = '/event/ShipmentRequest_Event__e';

export default class ShipmentRequestDatatable extends NavigationMixin(LightningElement) {
    region;
    columns = Object.values(COLUMNS);
    selectedStatuses = new Set();
    state = {
        loading: null,
        shipmentRequests: null,
        allShipmentRequests: null,
        error: null
    };
    subscriber;

    connectedCallback() {
        this.init();
        this.subscriberToShipmentRequestChannel();
    }

    disconnectedCallback() {
        if (this.subscriber) {
            this.subscriber.unsubscribeFromChannel();
            this.subscriber = null;
        }
    }

    get noShippingRequests() {
        return this.state?.shipmentRequests && this.state.shipmentRequests.length === 0;
    }

    get filterStatuses() {
        return Object.keys(STATUS_COLORS).map((status) => ({
            label: status,
            style: `background-color: ${STATUS_COLORS[status]}; cursor: pointer;`
        }));
    }

    get selectedFilterStatuses() {
        return this.selectedStatuses.size
            ? Array.from(this.selectedStatuses).map((status) => ({
                  label: status
              }))
            : null;
    }

    handleEventNotification = async (event) => {
        console.log('Event notification received:', JSON.stringify(event));
        if (event?.data?.payload?.Region__c && this.region && event.data.payload.Region__c === this.region) {
            await this.init();
            this.filterRecords();
        } else {
            console.warn('Not my region:', event.data.payload.Region__c, 'Expected:', this.region);
        }
    };

    subscriberToShipmentRequestChannel() {
        if (!this.subscriber) {
            this.subscriber = new PlatformEventSubscriber(CHANNEL_NAME, this.handleEventNotification, (error) => {
                console.error('Error subscribing to channel:', error);
            });
        }
        this.subscriber.subscribeToChannel();
    }

    async init() {
        try {
            this.setState({ loading: true, error: null });
            const data = await getShipmentRequests();
            this.region = data?.[0]?.Region__c;
            const shipmentRequests = this.transformShipmentRequests(data);
            this.setState({
                shipmentRequests,
                allShipmentRequests: shipmentRequests,
                loading: false
            });
        } catch (error) {
            this.setState({
                loading: false,
                error: error?.body.message || 'Error fetching shipment requests:'
            });
        }
    }

    async updateShipment(shipmentRequest) {
        try {
            await updateShipmentRequest({ shipmentRequest });
        } catch (error) {
            this.setState({
                loading: false,
                error: error?.body.message || 'Error updating shipment request'
            });
        }
    }

    setState(newState) {
        this.state = { ...this.state, ...newState };
    }

    transformShipmentRequests(shipmentRequests) {
        return shipmentRequests.map((shipmentRequest) => ({
            ...shipmentRequest,
            showInReviewMenu: !(shipmentRequest.Status__c === 'Assigned to Agent' || shipmentRequest.Status__c === 'Dispatch Failed'),
            showReadyForDispatchMenu: !(shipmentRequest.Status__c === 'In Review' || shipmentRequest.Status__c === 'Dispatch Failed'),
            backgroundColor: STATUS_COLORS[shipmentRequest.Status__c] ? 'background-color: ' + STATUS_COLORS[shipmentRequest.Status__c] : '',
            cells: Object.values(COLUMNS).map((col) => ({
                value: shipmentRequest[col.fieldName],
                urlId: col.type === 'url' ? shipmentRequest.Id : null,
                cellId: col.fieldName,
                icon: ICONS[col.fieldName] ? ICONS[col.fieldName][shipmentRequest[col.fieldName]] : null
            }))
        }));
    }

    filterRecords() {
        if (this.state.allShipmentRequests && this.selectedStatuses.size) {
            this.state.shipmentRequests = this.state.allShipmentRequests.filter((record) => this.selectedStatuses.has(record.Status__c));
            this.setState(this.state);
        } else {
            this.state.shipmentRequests = this.state.allShipmentRequests;
            this.setState(this.state);
        }
    }

    navigateToRecordPage(recordId) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Shipment_Request__c',
                actionName: 'view'
            }
        }).then((url) => window.open(url, '_blank'));
    }

    async handleUpdateShipment(event) {
        const recordId = event.target.dataset.recordId;
        const newStatus = event.target.value;
        const shipmentRequestId = event.target.dataset.shipmentRequestId;
        if (recordId && newStatus) {
            this.setState({ loading: true });
            await this.updateShipment({ Id: recordId, Status__c: newStatus, ShipmentRequest_Id__c: shipmentRequestId });
            this.setState({ loading: false });
            await this.init();
            this.filterRecords();
        }
    }

    handleRemoveFilter(event) {
        const status = event.target.dataset.label;
        if (status) {
            this.selectedStatuses.delete(status);
            this.selectedStatuses = new Set(this.selectedStatuses);
            this.filterRecords();
        }
    }

    handleFilterByStatus(event) {
        const status = event.target.dataset.label;
        if (status) {
            this.selectedStatuses.add(status);
            this.selectedStatuses = new Set(this.selectedStatuses);
            this.filterRecords();
        }
    }

    async handleNavigateToRecord(event) {
        event.preventDefault();
        const recordId = event.target.dataset.recordId;
        const status = event.target.dataset.status;
        const statusToAutoUpdate = 'Assigned to Agent';
        const statusToUpdateTo = 'In Review';
        if (status === statusToAutoUpdate) {
            await this.updateShipment({
                Id: recordId,
                Status__c: statusToUpdateTo
            });
            await this.init();
            this.filterRecords();
        }
        this.navigateToRecordPage(recordId);
    }
}