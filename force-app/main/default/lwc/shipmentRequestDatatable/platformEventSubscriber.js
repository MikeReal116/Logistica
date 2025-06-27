import { subscribe, unsubscribe } from 'lightning/empApi';

export default class PlatformEventSubscriber {
    constructor(channelName, callback, errorCallback) {
        this.channelName = channelName;
        this.callback = callback;
        this.errorCallback = errorCallback;
        this.subscription = null;
    }

    async subscribeToChannel(replayId = -1) {
        if (this.subscription) {
            console.warn('Already subscribed to channel: ', this.channelName);
            return;
        }
        try {
            this.subscription = await subscribe(this.channelName, replayId, this.callback);
            console.log('Subscribed to channel: ', this.channelName);
        } catch (error) {
            if (this.errorCallback) {
                this.errorCallback(error);
            } else {
                console.error('Subscription failed: ', error);
            }
        }
    }

    async unsubscribeFromChannel() {
        if (this.subscription) {
            try {
                await unsubscribe(this.subscription);
                this.subscription = null;
            } catch (error) {
                if (this.errorCallback) {
                    this.errorCallback(error);
                } else {
                    console.error('Unsubscription failed:', error);
                }
            }
        }
    }

    isSubscribed() {
        return this.subscription !== null;
    }
}